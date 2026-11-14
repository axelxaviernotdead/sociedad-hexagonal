-- Corre p_sql como un usuario (null = anónimo) y compara con lo esperado.
-- "Anda" = sin error y al menos una fila afectada o devuelta.
create schema if not exists prueba;
create or replace function prueba.como(p_uid text, p_sql text, p_debe_andar boolean, p_nombre text) returns text
language plpgsql as $$
declare n int; r text;
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_uid, ''), true);
  execute format('set local role %s', case when p_uid is null then 'anon' else 'authenticated' end);
  begin
    execute p_sql; get diagnostics n = row_count;
    r := case when p_debe_andar = (n > 0) then 'OK   ' else 'FALLA' end || ' ' || p_nombre || ' (filas: ' || n || ')';
  exception when others then
    r := case when p_debe_andar then 'FALLA' else 'OK   ' end || ' ' || p_nombre || ' (error: ' || sqlerrm || ')';
  end;
  reset role;
  return r;
end $$;
