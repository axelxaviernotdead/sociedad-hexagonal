-- ============================================================
-- Sociedad Hexagonal · esquema 0001
-- Ejecutar completo en el SQL Editor de Supabase.
-- ============================================================

create extension if not exists pgcrypto;
create extension if not exists citext;

-- ------------------------------------------------------------
-- Títulos y cargos
-- derivado: se otorga solo (utópico, testigo)
-- asignado: lo otorga el núcleo (fundador, operador, músico)
-- cargo: da permisos (núcleo, secretaría)
-- ------------------------------------------------------------
create table public.titulos (
  id     text primary key,
  nombre text not null,
  tipo   text not null check (tipo in ('derivado', 'asignado', 'cargo'))
);
insert into public.titulos values
  ('fundador',   'miembro fundador', 'asignado'),
  ('utopico',    'miembro utópico',  'derivado'),
  ('testigo',    'miembro testigo',  'derivado'),
  ('operador',   'miembro operador', 'asignado'),
  ('musico',     'miembro músico',   'asignado'),
  ('nucleo',     'núcleo',           'cargo'),
  ('secretario', 'secretaría',       'cargo');
alter table public.titulos enable row level security;
create policy "titulos legibles" on public.titulos for select using (true);

-- ------------------------------------------------------------
-- Lista de admisión: única puerta de entrada
-- ------------------------------------------------------------
create table public.lista_admision (
  email    citext primary key,
  alias    citext unique not null,
  agregado timestamptz not null default now()
);
alter table public.lista_admision enable row level security;  -- sin políticas: solo desde el panel de Supabase

-- ------------------------------------------------------------
-- Miembros
-- ------------------------------------------------------------
create table public.miembros (
  id           uuid primary key references auth.users on delete cascade,
  alias        citext unique not null check (char_length(alias) between 2 and 32),
  email        citext not null,
  invitado_por uuid references public.miembros,
  generacion   int not null default 0,
  estado       text not null default 'activo' check (estado in ('activo', 'revision', 'expulsado')),
  creado       timestamptz not null default now()
);
alter table public.miembros enable row level security;

create table public.miembro_titulos (
  miembro_id uuid references public.miembros on delete cascade,
  titulo     text references public.titulos,
  primary key (miembro_id, titulo)
);
alter table public.miembro_titulos enable row level security;
create policy "veo mis títulos" on public.miembro_titulos for select using (miembro_id = auth.uid());

create or replace function public.es_miembro() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from miembros where id = auth.uid() and estado = 'activo')
$$;

create or replace function public.tiene_titulo(t text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from miembro_titulos where miembro_id = auth.uid() and titulo = t)
$$;

-- Los miembros ven alias de otros miembros, nunca mails.
revoke all on public.miembros from anon, authenticated;
grant select (id, alias) on public.miembros to authenticated;
grant update (alias) on public.miembros to authenticated;
create policy "miembros ven alias" on public.miembros for select using (public.es_miembro());
create policy "cambio mi alias" on public.miembros for update using (id = auth.uid()) with check (id = auth.uid());

-- ------------------------------------------------------------
-- Utopías y calendario
-- ------------------------------------------------------------
create table public.utopias (
  id     serial primary key,
  numero int unique not null,
  fecha  timestamptz not null,
  estado text not null default 'anunciada' check (estado in ('anunciada', 'realizada'))
);
alter table public.utopias enable row level security;
create policy "utopías legibles" on public.utopias for select using (true);

create table public.eventos (
  id        serial primary key,
  fecha     timestamptz not null,
  titulo    text not null,
  detalle   text,
  utopia_id int references public.utopias on delete cascade
);
alter table public.eventos enable row level security;
create policy "miembros ven el calendario" on public.eventos for select using (public.es_miembro());

-- Confirmación previa de asistencia
create table public.asistencias (
  utopia_id   int  references public.utopias on delete cascade,
  miembro_id  uuid references public.miembros on delete cascade default auth.uid(),
  estado      text not null check (estado in ('asistire', 'no_asistire')),
  actualizado timestamptz not null default now(),
  primary key (utopia_id, miembro_id)
);
alter table public.asistencias enable row level security;
create policy "veo mi asistencia" on public.asistencias for select using (miembro_id = auth.uid());
create policy "confirmo mi asistencia" on public.asistencias for insert with check (miembro_id = auth.uid() and public.es_miembro());
create policy "cambio mi asistencia" on public.asistencias for update using (miembro_id = auth.uid()) with check (miembro_id = auth.uid());

create or replace function public.confirmados(p_utopia int) returns int
language sql stable security definer set search_path = public as $$
  select case when es_miembro() then (select count(*)::int from asistencias where utopia_id = p_utopia and estado = 'asistire') end
$$;

-- El lugar se revela 48 h antes, solo a quien confirmó.
create table public.utopia_lugar (
  utopia_id int primary key references public.utopias on delete cascade,
  lugar     text not null
);
alter table public.utopia_lugar enable row level security;
create policy "lugar para confirmados" on public.utopia_lugar for select using (
  public.es_miembro()
  and exists (select 1 from public.asistencias a
              where a.utopia_id = utopia_lugar.utopia_id and a.miembro_id = auth.uid() and a.estado = 'asistire')
  and now() >= (select u.fecha from public.utopias u where u.id = utopia_lugar.utopia_id) - interval '48 hours'
);

-- ------------------------------------------------------------
-- Presentaciones
-- Las rutas de archivos apuntan al bucket privado "archivo".
-- ------------------------------------------------------------
create table public.presentaciones (
  id                serial primary key,
  numero            int unique not null,
  utopia_id         int not null references public.utopias,
  autor_id          uuid references public.miembros,
  titulo            text not null,
  resumen           text,
  duracion_s        int,
  temas             text[] not null default '{}',
  visibilidad       text not null default 'miembros' check (visibilidad in ('miembros', 'publico')),
  audio_path        text,
  video_path        text,
  diapositivas_path text,
  capitulos         jsonb not null default '[]'   -- [{"t": 252, "titulo": "..."}]
);
alter table public.presentaciones enable row level security;
revoke update on public.presentaciones from authenticated;
grant update (visibilidad) on public.presentaciones to authenticated;
create policy "presentaciones visibles" on public.presentaciones for select using (visibilidad = 'publico' or public.es_miembro());
create policy "autor decide visibilidad" on public.presentaciones for update using (autor_id = auth.uid()) with check (autor_id = auth.uid());

-- Archivo: completo para miembros, solo lo público para el resto.
create or replace function public.archivo()
returns table (numero int, titulo text, alias text, utopia int, duracion_s int, audio boolean, video boolean, visibilidad text)
language sql stable security definer set search_path = public as $$
  select p.numero, p.titulo, m.alias::text, u.numero, p.duracion_s,
         p.audio_path is not null, p.video_path is not null, p.visibilidad
    from presentaciones p
    join utopias u on u.id = p.utopia_id
    left join miembros m on m.id = p.autor_id
   where p.visibilidad = 'publico' or es_miembro()
   order by p.numero desc
$$;

create or replace function public.presentacion(n int) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'numero', p.numero, 'titulo', p.titulo, 'resumen', p.resumen, 'duracion_s', p.duracion_s,
    'temas', p.temas, 'visibilidad', p.visibilidad, 'capitulos', p.capitulos,
    'audio_path', p.audio_path, 'video_path', p.video_path, 'diapositivas_path', p.diapositivas_path,
    'alias', m.alias, 'utopia', u.numero, 'fecha', u.fecha, 'es_mia', p.autor_id = auth.uid())
    from presentaciones p
    join utopias u on u.id = p.utopia_id
    left join miembros m on m.id = p.autor_id
   where p.numero = n and (p.visibilidad = 'publico' or es_miembro())
$$;

create or replace function public.datos_publicos() returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'primera', (select min(fecha) from utopias where estado = 'realizada'),
    'realizadas', (select count(*) from utopias where estado = 'realizada'),
    'publicas', (select count(*) from presentaciones where visibilidad = 'publico'),
    'total', (select count(*) from presentaciones))
$$;

-- ------------------------------------------------------------
-- Libro de actas: bajo llave
-- ------------------------------------------------------------
create table public.actas (
  utopia_id  int  references public.utopias on delete cascade,
  miembro_id uuid references public.miembros on delete cascade,
  primary key (utopia_id, miembro_id)
);
alter table public.actas enable row level security;
create policy "veo mi asistencia real" on public.actas for select using (miembro_id = auth.uid());

create table public.actas_bitacora (
  id      bigserial primary key,
  lector  uuid not null,
  accion  text not null,
  momento timestamptz not null default now()
);
alter table public.actas_bitacora enable row level security;
create policy "secretaría ve la bitácora" on public.actas_bitacora for select using (public.tiene_titulo('secretario'));

create or replace function public.consultar_actas(p_utopia int default null)
returns table (utopia int, alias text)
language plpgsql security definer set search_path = public as $$
begin
  if not tiene_titulo('secretario') then raise exception 'acceso denegado'; end if;
  insert into actas_bitacora (lector, accion)
    values (auth.uid(), 'lectura: ' || coalesce('N°' || (select numero from utopias where id = p_utopia), 'libro completo'));
  return query select u.numero, m.alias::text
    from actas a join utopias u on u.id = a.utopia_id join miembros m on m.id = a.miembro_id
   where p_utopia is null or a.utopia_id = p_utopia
   order by u.numero, m.alias;
end $$;

create or replace function public.registrar_acta(p_utopia int, p_miembro uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not tiene_titulo('secretario') then raise exception 'acceso denegado'; end if;
  insert into actas values (p_utopia, p_miembro) on conflict do nothing;
  insert into actas_bitacora (lector, accion)
    values (auth.uid(), 'escritura: N°' || (select numero from utopias where id = p_utopia));
end $$;

-- ------------------------------------------------------------
-- Registro personal
-- ------------------------------------------------------------
create or replace function public.mi_registro() returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'alias', m.alias, 'email', m.email, 'creado', m.creado,
    'titulos', array(
        select t.nombre from titulos t
         where exists (select 1 from miembro_titulos mt where mt.miembro_id = m.id and mt.titulo = t.id)
            or (t.id = 'utopico' and exists (select 1 from presentaciones p where p.autor_id = m.id))
            or (t.id = 'testigo' and exists (select 1 from actas a where a.miembro_id = m.id))
         order by t.tipo, t.nombre),
    'asistencia', (select coalesce(json_agg(json_build_object('numero', u.numero,
                     'presente', exists (select 1 from actas a where a.utopia_id = u.id and a.miembro_id = m.id))
                     order by u.numero), '[]')
                     from utopias u where u.estado = 'realizada'),
    'presentaciones', (select coalesce(json_agg(json_build_object('numero', p.numero, 'titulo', p.titulo,
                     'utopia', u.numero, 'visibilidad', p.visibilidad) order by p.numero), '[]')
                     from presentaciones p join utopias u on u.id = p.utopia_id where p.autor_id = m.id))
    from miembros m where m.id = auth.uid()
$$;

-- ------------------------------------------------------------
-- Foro
-- ------------------------------------------------------------
create table public.hilos (
  id         serial primary key,
  titulo     text not null check (char_length(titulo) between 3 and 160),
  tema       text not null,
  autor_id   uuid not null references public.miembros,
  utopia_id  int references public.utopias,
  creado     timestamptz not null default now(),
  actividad  timestamptz not null default now(),
  respuestas int not null default 0
);
alter table public.hilos enable row level security;
create policy "miembros leen hilos" on public.hilos for select using (public.es_miembro());

create table public.mensajes (
  id       bigserial primary key,
  hilo_id  int not null references public.hilos on delete cascade,
  numero   int not null,
  autor_id uuid not null default auth.uid() references public.miembros,
  cuerpo   text not null check (char_length(cuerpo) between 1 and 20000),
  creado   timestamptz not null default now(),
  editado  timestamptz,
  unique (hilo_id, numero)
);
alter table public.mensajes enable row level security;
revoke update on public.mensajes from authenticated;
grant update (cuerpo) on public.mensajes to authenticated;
create policy "miembros leen mensajes" on public.mensajes for select using (public.es_miembro());
create policy "miembros responden" on public.mensajes for insert with check (autor_id = auth.uid() and public.es_miembro());
create policy "edito 30 minutos" on public.mensajes for update
  using (autor_id = auth.uid() and creado > now() - interval '30 minutes') with check (autor_id = auth.uid());

-- Numeración por hilo y actividad
create or replace function public.numerar_mensaje() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform 1 from hilos where id = new.hilo_id for update;
  select coalesce(max(numero), 0) + 1 into new.numero from mensajes where hilo_id = new.hilo_id;
  new.creado := now();
  return new;
end $$;
create trigger numerar before insert on public.mensajes for each row execute function public.numerar_mensaje();

create or replace function public.actividad_hilo() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update hilos set actividad = now(), respuestas = new.numero - 1 where id = new.hilo_id;
  return null;
end $$;
create trigger actividad after insert on public.mensajes for each row execute function public.actividad_hilo();

create or replace function public.abrir_hilo(p_titulo text, p_tema text, p_cuerpo text) returns int
language plpgsql security definer set search_path = public as $$
declare v_id int;
begin
  if not es_miembro() then raise exception 'acceso denegado'; end if;
  insert into hilos (titulo, tema, autor_id) values (p_titulo, p_tema, auth.uid()) returning id into v_id;
  insert into mensajes (hilo_id, autor_id, cuerpo, numero) values (v_id, auth.uid(), p_cuerpo, 0);
  return v_id;
end $$;

-- ------------------------------------------------------------
-- Portal: única puerta de entrada
-- Un usuario solo se crea si su mail está en la lista de admisión.
-- ------------------------------------------------------------
create or replace function public.portal() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_alias citext;
begin
  select alias into v_alias from lista_admision where email = new.email::citext;
  if v_alias is null then raise exception 'acceso no admitido'; end if;
  insert into miembros (id, alias, email) values (new.id, v_alias, new.email);
  return new;
end $$;
create trigger portal after insert on auth.users for each row execute function public.portal();

-- ------------------------------------------------------------
-- Almacenamiento: bucket privado. Un archivo se puede leer solo
-- si pertenece a una presentación que quien pide puede ver.
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public) values ('archivo', 'archivo', false)
  on conflict (id) do nothing;

create policy "archivo según visibilidad" on storage.objects for select using (
  bucket_id = 'archivo' and exists (
    select 1 from public.presentaciones p
     where name in (p.audio_path, p.video_path, p.diapositivas_path)
       and (p.visibilidad = 'publico' or public.es_miembro())));

-- ------------------------------------------------------------
-- Permisos explícitos (no depender de los permisos por defecto)
-- ------------------------------------------------------------
grant usage on schema public to anon, authenticated;
grant select on public.titulos, public.utopias, public.presentaciones to anon, authenticated;
grant select on public.eventos, public.asistencias, public.utopia_lugar, public.actas,
                public.actas_bitacora, public.hilos, public.mensajes, public.miembro_titulos to authenticated;
grant insert, update on public.asistencias to authenticated;
grant insert on public.mensajes to authenticated;
grant usage on sequence public.mensajes_id_seq to authenticated;
revoke execute on function public.numerar_mensaje(), public.actividad_hilo(), public.portal() from anon, authenticated, public;
