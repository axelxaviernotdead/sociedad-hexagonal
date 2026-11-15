-- ============================================================
-- Sociedad Hexagonal · 0005 · foro sin temas
-- Los hilos se abren solo con título y cuerpo. La columna tema queda (los hilos viejos la conservan)
-- pero deja de ser obligatoria. abrir_hilo de tres argumentos sigue existiendo por compatibilidad.
-- Ejecutar completo en el SQL Editor de Supabase, después de 0004.
-- ============================================================

alter table public.hilos alter column tema drop not null;

create or replace function public.abrir_hilo(p_titulo text, p_cuerpo text) returns int
language plpgsql security definer set search_path = public as $$
declare v_id int;
begin
  if not es_miembro() then raise exception 'acceso denegado'; end if;
  insert into hilos (titulo, autor_id) values (p_titulo, auth.uid()) returning id into v_id;
  insert into mensajes (hilo_id, autor_id, cuerpo, numero) values (v_id, auth.uid(), p_cuerpo, 0);
  return v_id;
end $$;

revoke execute on function public.abrir_hilo(text, text) from public, anon;
grant execute on function public.abrir_hilo(text, text) to authenticated;
