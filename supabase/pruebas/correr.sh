#!/bin/bash
# Prueba las migraciones contra un Postgres local (NO contra Supabase).
# Crea la base "sh_pruebas" desde cero, carga un mínimo de lo que Supabase provee, todas las migraciones,
# los datos de ejemplo y tres usuarios, y corre cada archivo de prueba. Cada línea dice OK o FALLA.
# Conexión por las variables estándar de psql (PGHOST, PGPORT, PGUSER). Uso: supabase/pruebas/correr.sh
set -e
D=$(cd "$(dirname "$0")" && pwd)
P="psql -v ON_ERROR_STOP=1 -q -X"
$P -c 'drop database if exists sh_pruebas' -c 'create database sh_pruebas' >/dev/null
P="$P -d sh_pruebas"
$P -f "$D/supabase_minimo.sql"
for f in "$D"/../migrations/*.sql; do $P -f "$f"; done
$P -f "$D/../ejemplo.sql" -f "$D/usuarios.sql" -f "$D/ayuda.sql"
for f in "$D"/0*.sql; do
  echo "== $(basename "$f")"
  psql -X -q -t -A -d sh_pruebas -f "$f" 2>&1 | grep -E '^(OK|FALLA|psql)' || true
done
