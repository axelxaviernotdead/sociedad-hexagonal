-- ============================================================
-- Sociedad Hexagonal · 0003 · libro de visitas
-- Notas libres en el inicio. Cada miembro mueve, edita y borra solo las suyas;
-- el núcleo puede borrar cualquiera para moderar.
-- Fuente y color son claves de listas cerradas: nunca CSS crudo.
-- Ejecutar completo en el SQL Editor de Supabase, después de 0002.
-- ============================================================

create table public.libro_notas (
  id       bigserial primary key,
  autor_id uuid not null default auth.uid() references public.miembros on delete cascade,
  texto    text not null check (char_length(trim(texto)) between 1 and 280),
  -- Posición de la esquina superior izquierda, como fracción del tablero (0 a 1).
  x        real not null default 0.5 check (x between 0 and 1),
  y        real not null default 0.5 check (y between 0 and 1),
  fuente   text not null default 'sitio'
           check (fuente in ('sitio', 'serif', 'mono', 'manuscrita', 'redonda', 'angosta')),
  color    text not null default 'negro'
           check (color in ('negro', 'gris', 'rojo', 'azul', 'verde', 'naranja', 'violeta', 'rosa')),
  creado   timestamptz not null default now(),
  movido   timestamptz not null default now()   -- la última nota tocada queda arriba
);
alter table public.libro_notas enable row level security;

create index libro_notas_autor on public.libro_notas (autor_id);

-- movido y creado los pone la base, no quien escribe.
create or replace function public.libro_tocar() returns trigger
language plpgsql set search_path = public as $$
begin
  new.movido := now();
  if tg_op = 'INSERT' then new.creado := now(); end if;
  return new;
end $$;
create trigger tocar before insert or update on public.libro_notas
  for each row execute function public.libro_tocar();

create policy "miembros leen el libro" on public.libro_notas for select using (public.es_miembro());

-- Hasta 20 notas por miembro, para que el tablero no se llene de una sola persona.
create policy "escribo en el libro" on public.libro_notas for insert with check (
  autor_id = auth.uid()
  and public.es_miembro()
  and (select count(*) from public.libro_notas n where n.autor_id = auth.uid()) < 20
);
create policy "muevo y cambio lo mío" on public.libro_notas for update
  using (autor_id = auth.uid() and public.es_miembro())
  with check (autor_id = auth.uid() and public.es_miembro());
create policy "borro lo mío; el núcleo modera" on public.libro_notas for delete
  using ((autor_id = auth.uid() and public.es_miembro()) or public.es_nucleo());

grant select, insert, delete on public.libro_notas to authenticated;
grant update (texto, x, y, fuente, color) on public.libro_notas to authenticated;
grant usage on sequence public.libro_notas_id_seq to authenticated;
revoke execute on function public.libro_tocar() from anon, authenticated, public;
