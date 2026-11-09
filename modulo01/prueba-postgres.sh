#!/bin/bash
# Prueba de humo de PostgreSQL + pgvector (bloque 06): crea una base temporal,
# habilita la extensión vector, ordena por distancia y borra la base.
# Se ejecuta en el ANFITRIÓN, con PostgreSQL levantado (make pg-up). No toca la base bigdata.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

PSQL="docker compose -f postgres/compose.yaml exec -T postgres psql -U alumno -v ON_ERROR_STOP=1 -qAt"
BASE="prueba_$(date +%Y%m%d%H%M%S)"

comprobar() {
    local descripcion="$1"
    local salida="$2"
    local esperado="$3"
    if printf '%s\n' "$salida" | grep -qxF -- "$esperado"; then
        echo "  ✅ ${descripcion}"
    else
        echo "  ❌ ${descripcion}: no aparece '${esperado}'"
        printf '%s\n' "$salida" | sed 's/^/     /'
        exit 1
    fi
}

limpiar() {
    echo "🧹 Borrando la base ${BASE}"
    $PSQL -d bigdata -c "DROP DATABASE IF EXISTS ${BASE};" >/dev/null 2>&1 || true
}
trap limpiar EXIT

echo "🧪 1/2 Servidor y extensión"
$PSQL -d bigdata -c "CREATE DATABASE ${BASE};"
SALIDA="$($PSQL -d "$BASE" -c "CREATE EXTENSION vector; SELECT current_setting('server_version_num')::int / 10000; SELECT extversion FROM pg_extension WHERE extname = 'vector';")"
comprobar "PostgreSQL 17" "$SALIDA" "17"
comprobar "pgvector 0.8.1" "$SALIDA" "0.8.1"

echo "🧪 2/2 Tabla relacional + vecino más próximo"
SALIDA="$($PSQL -d "$BASE" <<'SQL'
CREATE TABLE documentos (id serial PRIMARY KEY, titulo text NOT NULL, embedding vector(3));
INSERT INTO documentos (titulo, embedding) VALUES
  ('devoluciones', '[0.10,0.85,0.20]'), ('envios', '[0.80,0.10,0.30]'), ('garantia', '[0.15,0.75,0.30]');
SELECT count(*) FROM documentos;
SELECT titulo FROM documentos ORDER BY embedding <-> '[0.10,0.85,0.20]' LIMIT 1;
SQL
)"
comprobar "3 filas" "$SALIDA" "3"
comprobar "más próximo = devoluciones" "$SALIDA" "devoluciones"

echo "✅ Prueba de PostgreSQL completada"
