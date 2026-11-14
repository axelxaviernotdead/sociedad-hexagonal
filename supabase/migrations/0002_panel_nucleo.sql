-- ============================================================
-- Sociedad Hexagonal · 0002 · panel del núcleo, parte 1
-- Alta y edición de utopías, eventos y lugar, con cargo "nucleo".
-- Ejecutar completo en el SQL Editor de Supabase, después de 0001.
-- ============================================================

-- Núcleo: miembro activo con el cargo. Un miembro expulsado pierde el panel aunque conserve el título.
create or replace function public.es_nucleo() returns boolean
language sql stable security definer set search_path = public as $$
  select es_miembro() and tiene_titulo('nucleo')
$$;

-- ------------------------------------------------------------
-- Utopías
-- Se borran solo si están anunciadas y no tienen actas ni presentaciones:
-- borrar una realizada arrastraría el libro de actas (on delete cascade).
-- ------------------------------------------------------------
create policy "núcleo crea utopías" on public.utopias for insert with check (public.es_nucleo());
create policy "núcleo edita utopías" on public.utopias for update using (public.es_nucleo()) with check (public.es_nucleo());
create policy "núcleo borra utopías anunciadas" on public.utopias for delete using (
  public.es_nucleo()
  and estado = 'anunciada'
  and not exists (select 1 from public.actas a where a.utopia_id = utopias.id)
  and not exists (select 1 from public.presentaciones p where p.utopia_id = utopias.id)
);

-- ------------------------------------------------------------
-- Eventos del calendario
-- ------------------------------------------------------------
create policy "núcleo crea eventos" on public.eventos for insert with check (public.es_nucleo());
create policy "núcleo edita eventos" on public.eventos for update using (public.es_nucleo()) with check (public.es_nucleo());
create policy "núcleo borra eventos" on public.eventos for delete using (public.es_nucleo());

-- ------------------------------------------------------------
-- Lugar: el núcleo lo ve siempre (para cargarlo); el resto sigue con la regla de 48 h.
-- ------------------------------------------------------------
create policy "núcleo ve los lugares" on public.utopia_lugar for select using (public.es_nucleo());
create policy "núcleo carga lugares" on public.utopia_lugar for insert with check (public.es_nucleo());
create policy "núcleo edita lugares" on public.utopia_lugar for update using (public.es_nucleo()) with check (public.es_nucleo());
create policy "núcleo borra lugares" on public.utopia_lugar for delete using (public.es_nucleo());

-- ------------------------------------------------------------
-- Guardar una utopía con su evento y su lugar, en una sola transacción.
-- security invoker: corre con los permisos de quien llama, así que las políticas de arriba aplican igual.
-- p_id null crea; si no, edita. Devuelve el id.
-- Toda utopía tiene un evento con utopia_id: sin él no aparece en el calendario con los botones de asistencia.
-- ------------------------------------------------------------
create or replace function public.guardar_utopia(
  p_id int, p_numero int, p_fecha timestamptz, p_estado text, p_lugar text
) returns int
language plpgsql security invoker set search_path = public as $$
declare
  v_id     int;
  v_numero int;
  v_titulo text := 'Utopía N°' || lpad(p_numero::text, 2, '0');
begin
  if not es_nucleo() then raise exception 'acceso denegado'; end if;

  if p_id is null then
    insert into utopias (numero, fecha, estado) values (p_numero, p_fecha, p_estado) returning id into v_id;
  else
    select numero into v_numero from utopias where id = p_id;
    update utopias set numero = p_numero, fecha = p_fecha, estado = p_estado where id = p_id returning id into v_id;
    if v_id is null then raise exception 'no existe la utopía'; end if;
  end if;

  -- Evento: se crea si falta; la fecha sigue a la utopía; el título solo cambia si cambió el número.
  update eventos set fecha = p_fecha,
                     titulo = case when v_numero is distinct from p_numero then v_titulo else titulo end
   where utopia_id = v_id;
  if not found then
    insert into eventos (fecha, titulo, utopia_id) values (p_fecha, v_titulo, v_id);
  end if;

  if nullif(trim(p_lugar), '') is null then
    delete from utopia_lugar where utopia_id = v_id;
  else
    insert into utopia_lugar (utopia_id, lugar) values (v_id, trim(p_lugar))
      on conflict (utopia_id) do update set lugar = excluded.lugar;
  end if;

  return v_id;
end $$;

-- ------------------------------------------------------------
-- Permisos explícitos. RLS decide quién; esto habilita qué columnas.
-- ------------------------------------------------------------
grant insert, delete on public.utopias, public.eventos, public.utopia_lugar to authenticated;
grant update (numero, fecha, estado) on public.utopias to authenticated;
grant update (fecha, titulo, detalle, utopia_id) on public.eventos to authenticated;
grant update (lugar) on public.utopia_lugar to authenticated;
grant usage on sequence public.utopias_id_seq, public.eventos_id_seq to authenticated;
revoke execute on function public.guardar_utopia(int, int, timestamptz, text, text) from public, anon;
grant execute on function public.guardar_utopia(int, int, timestamptz, text, text) to authenticated;
