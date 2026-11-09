#!/bin/bash
# Prueba de humo de Hive (bloque 07): ejecuta hive/sql/recorrido.sql sobre una base
# y una ruta HDFS propias de la prueba, comprueba los resultados y lo borra todo.
# Se ejecuta en el ANFITRIÓN, con el clúster y Hive levantados (make up hive-up).
# No toca la base m01_empresa ni /user/hive/external del alumnado.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

HADOOP="docker compose -f hadoop/compose.yaml"
HIVE="docker compose -f hive/compose.yaml"
MARCA="$(date +%Y%m%d%H%M%S)"
BASE_DATOS="m01_prueba_${MARCA}"
RUTA_HDFS="/user/hive/external/prueba-${MARCA}"
JDBC="jdbc:hive2://localhost:10000/default"

comprobar() {
    local descripcion="$1"
    local salida="$2"
    local patron="$3"
    if printf '%s\n' "$salida" | grep -qE -- "$patron"; then
        echo "  ✅ ${descripcion}"
    else
        echo "  ❌ ${descripcion}: no aparece '${patron}'"
        printf '%s\n' "$salida" | sed 's/^/     /'
        exit 1
    fi
}

limpiar() {
    echo "🧹 Limpiando ${BASE_DATOS} y ${RUTA_HDFS}"
    $HIVE exec -T hiveserver2 beeline -u "$JDBC" -n hive --silent=true \
        -e "DROP DATABASE IF EXISTS ${BASE_DATOS} CASCADE;" >/dev/null 2>&1 || true
    $HADOOP exec -T --user hadoop master hdfs dfs -rm -r -f -skipTrash "$RUTA_HDFS" >/dev/null 2>&1 || true
}
trap limpiar EXIT

echo "🧪 Recorrido del bloque 07 en la base ${BASE_DATOS}"
SQL="$(sed -e "s/m01_empresa/${BASE_DATOS}/g" \
           -e "s#/user/hive/external/#${RUTA_HDFS}/#g" hive/sql/recorrido.sql)"
SALIDA="$($HIVE exec -T hiveserver2 bash -c "cat > /tmp/prueba.sql && beeline -u '${JDBC}' -n hive --silent=true -f /tmp/prueba.sql 2>/dev/null; rm -f /tmp/prueba.sql" <<< "$SQL")"

comprobar "empleados_texto: 3 filas" "$SALIDA" '^\| 3 +\|$'
comprobar "media de datos = 34000" "$SALIDA" '\| datos +\| 2 +\| 34000\.0 +\|'
comprobar "JOIN: Bruno → Luis" "$SALIDA" '\| Bruno +\| Luis +\|'
comprobar "partición fecha=2026-10-22" "$SALIDA" 'fecha=2026-10-22'
comprobar "total de la partición = 75.00" "$SALIDA" '\| 2026-10-22 +\| 75\.00 +\|'

PARQUET="$($HADOOP exec -T --user hadoop master hdfs dfs -ls -R "$RUTA_HDFS")"
comprobar "Parquet externo en HDFS" "$PARQUET" "${RUTA_HDFS}/empleados_parquet/"

echo "✅ Prueba de Hive completada"
