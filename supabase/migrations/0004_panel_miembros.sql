-- ============================================================
-- Sociedad Hexagonal · 0004 · panel del núcleo, parte 2: miembros
-- Admisión de mails en lote, títulos y cargos, expulsión y readmisión.
-- Todo pasa por funciones que exigen núcleo y dejan constancia en nucleo_bitacora.
-- El núcleo ve mails solo de la lista de admisión pendiente (personas que todavía no
-- entraron); nunca los de los miembros.
-- Ejecutar completo en el SQL Editor de Supabase, después de 0003.
-- ============================================================

-- ------------------------------------------------------------
-- Bitácora del núcleo: solo se escribe desde las funciones de abajo.
-- ------------------------------------------------------------
create table public.nucleo_bitacora (
  id       bigserial primary key,
  actor    uuid references public.miembros on delete set null,   -- null si el miembro se borró
  accion   text not null,
  objetivo text not null,
  momento  timestamptz not null default now()
);
alter table public.nucleo_bitacora enable row level security;
create policy "núcleo ve la bitácora" on public.nucleo_bitacora for select using (public.es_nucleo());
grant select on public.nucleo_bitacora to authenticated;

create or replace function public.anotar(p_accion text, p_objetivo text) returns void
language sql security definer set search_path = public as $$
  insert into nucleo_bitacora (actor, accion, objetivo) values (auth.uid(), p_accion, p_objetivo)
$$;
revoke execute on function public.anotar(text, text) from public, anon, authenticated;

-- ------------------------------------------------------------
-- Alias libre: el pedido si nadie lo usa (ni en miembros ni en la lista); si no, con un número.
-- ------------------------------------------------------------
create or replace function public.alias_libre(p_base text, p_email citext default null) returns citext
language plpgsql stable security definer set search_path = public as $$
declare v citext; n int := 1;
begin
  v := p_base;
  while exists (select 1 from miembros where alias = v)
     or exists (select 1 from lista_admision where alias = v and email is distinct from p_email) loop
    n := n + 1;
    v := p_base || n;
  end loop;
  return v;
end $$;
revoke execute on function public.alias_libre(text, citext) from public, anon, authenticated;

-- Portal: si el alias de la lista ya lo tomó otro miembro (por ejemplo, alguien que cambió el suyo),
-- la persona entra con el alias numerado en vez de quedar afuera por un error de clave única.
create or replace function public.portal() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_alias citext;
begin
  select alias into v_alias from lista_admision where email = new.email::citext;
  if v_alias is null then raise exception 'acceso no admitido'; end if;
  if exists (select 1 from miembros where alias = v_alias) then
    v_alias := alias_libre(v_alias::text, new.email::citext);
  end if;
  insert into miembros (id, alias, email) values (new.id, v_alias, new.email);
  return new;
end $$;

-- ------------------------------------------------------------
-- Lecturas del panel
-- ------------------------------------------------------------
-- Miembros con sus títulos asignados y cargos, y los derivados calculados. Sin mails.
create or replace function public.nucleo_miembros()
returns table (id uuid, alias text, estado text, creado timestamptz, titulos text[], utopico boolean, testigo boolean)
language plpgsql stable security definer set search_path = public as $$
begin
  if not es_nucleo() then raise exception 'acceso denegado'; end if;
  return query
    select m.id, m.alias::text, m.estado, m.creado,
           coalesce(array(select mt.titulo from miembro_titulos mt where mt.miembro_id = m.id order by mt.titulo), '{}'),
           exists (select 1 from presentaciones p where p.autor_id = m.id),
           exists (select 1 from actas a where a.miembro_id = m.id)
      from miembros m
     order by m.alias;
end $$;

-- Admitidos que todavía no entraron.
create or replace function public.nucleo_admision()
returns table (email text, alias text, agregado timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not es_nucleo() then raise exception 'acceso denegado'; end if;
  return query
    select l.email::text, l.alias::text, l.agregado
      from lista_admision l
     where not exists (select 1 from miembros m where m.email = l.email)
     order by l.agregado desc, l.email;
end $$;

-- ------------------------------------------------------------
-- Admisión en lote: mails separados por saltos de línea, comas, punto y coma o espacios.
-- Ignora lo que no parece un mail y los que ya estaban. Alias inicial: lo anterior a la @.
-- ------------------------------------------------------------
create or replace function public.admitir(p_lista text)
returns table (email text, alias text)
language plpgsql security definer set search_path = public as $$
declare r record; v_base text; v_alias citext; n int := 0;
begin
  if not es_nucleo() then raise exception 'acceso denegado'; end if;
  if char_length(p_lista) > 50000 then raise exception 'lista demasiado larga'; end if;
  for r in
    select distinct lower(trim(m)) as e
      from regexp_split_to_table(p_lista, '[\s,;]+') as m
     where m ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
     order by 1
  loop
    continue when exists (select 1 from lista_admision l where l.email = r.e::citext);
    n := n + 1;
    if n > 500 then raise exception 'más de 500 mails nuevos: dividí la lista'; end if;
    v_base := left(regexp_replace(split_part(r.e, '@', 1), '[^[:alnum:]._-]', '', 'g'), 24);
    if char_length(v_base) < 2 then v_base := 'miembro' || v_base; end if;
    v_alias := alias_libre(v_base);
    insert into lista_admision (email, alias) values (r.e, v_alias);
    email := r.e; alias := v_alias::text;
    return next;
  end loop;
  if n > 0 then perform anotar('admisión', n || ' mail' || case when n = 1 then '' else 's' end); end if;
end $$;

-- Quitar a alguien de la lista solo si todavía no entró. Quien ya es miembro se expulsa, no se "desadmite".
create or replace function public.quitar_admision(p_email text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not es_nucleo() then raise exception 'acceso denegado'; end if;
  if exists (select 1 from miembros where email = p_email::citext) then raise exception 'ya es miembro'; end if;
  delete from lista_admision where email = p_email::citext;
  if not found then raise exception 'no está en la lista'; end if;
  perform anotar('quitó de la admisión', p_email);
end $$;

-- ------------------------------------------------------------
-- Títulos asignados y cargos. Los derivados (utópico, testigo) no se dan: se calculan.
-- Nadie se saca su propio cargo de núcleo: el panel nunca queda sin nadie por error.
-- ------------------------------------------------------------
create or replace function public.dar_titulo(p_miembro uuid, p_titulo text) returns void
language plpgsql security definer set search_path = public as $$
declare v_alias text;
begin
  if not es_nucleo() then raise exception 'acceso denegado'; end if;
  if not exists (select 1 from titulos where id = p_titulo and tipo in ('asignado', 'cargo')) then
    raise exception 'ese título no se asigna';
  end if;
  select alias into v_alias from miembros where id = p_miembro;
  if v_alias is null then raise exception 'no existe ese miembro'; end if;
  insert into miembro_titulos (miembro_id, titulo) values (p_miembro, p_titulo) on conflict do nothing;
  if found then perform anotar('dio ' || p_titulo, v_alias); end if;
end $$;

create or replace function public.sacar_titulo(p_miembro uuid, p_titulo text) returns void
language plpgsql security definer set search_path = public as $$
declare v_alias text;
begin
  if not es_nucleo() then raise exception 'acceso denegado'; end if;
  if p_miembro = auth.uid() and p_titulo = 'nucleo' then raise exception 'no podés sacarte el cargo de núcleo'; end if;
  select alias into v_alias from miembros where id = p_miembro;
  delete from miembro_titulos where miembro_id = p_miembro and titulo = p_titulo;
  if found then perform anotar('sacó ' || p_titulo, v_alias); end if;
end $$;

-- ------------------------------------------------------------
-- Expulsión y readmisión. Nadie se expulsa a sí mismo.
-- Un expulsado pierde todo acceso (es_miembro) y sus cargos dejan de valer (es_nucleo exige es_miembro),
-- aunque conserve los títulos guardados.
-- ------------------------------------------------------------
create or replace function public.cambiar_estado(p_miembro uuid, p_estado text) returns void
language plpgsql security definer set search_path = public as $$
declare v_alias text;
begin
  if not es_nucleo() then raise exception 'acceso denegado'; end if;
  if p_estado not in ('activo', 'expulsado') then raise exception 'estado no válido'; end if;
  if p_miembro = auth.uid() then raise exception 'no podés cambiar tu propio estado'; end if;
  update miembros set estado = p_estado where id = p_miembro and estado <> p_estado returning alias into v_alias;
  if v_alias is not null then
    perform anotar(case when p_estado = 'expulsado' then 'expulsó' else 'readmitió' end, v_alias);
  end if;
end $$;

-- ------------------------------------------------------------
-- Permisos: solo usuarios con sesión pueden llamar; cada función exige núcleo adentro.
-- ------------------------------------------------------------
revoke execute on function public.nucleo_miembros(), public.nucleo_admision(), public.admitir(text),
  public.quitar_admision(text), public.dar_titulo(uuid, text), public.sacar_titulo(uuid, text),
  public.cambiar_estado(uuid, text) from public, anon;
grant execute on function public.nucleo_miembros(), public.nucleo_admision(), public.admitir(text),
  public.quitar_admision(text), public.dar_titulo(uuid, text), public.sacar_titulo(uuid, text),
  public.cambiar_estado(uuid, text) to authenticated;
