#!/bin/bash
# Prueba de humo del clúster de M01: HDFS con 3 DataNodes, wordcount en YARN
# (M01-YARN-01) y Hadoop Streaming con Python (M01-MR-01).
# Se ejecuta en el ANFITRIÓN, con el clúster levantado (make up).
# Escribe solo bajo /pruebas/<fecha> en HDFS: no toca /datos del alumnado.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

COMPOSE="docker compose -f hadoop/compose.yaml"
MARCA="$(date +%Y%m%d-%H%M%S)"
BASE_HDFS="/pruebas/${MARCA}"
TRABAJO="/home/hadoop/pruebas-${MARCA}"

en_master() {
    $COMPOSE exec -T --user hadoop master bash -c "$1"
}

comprobar() {
    local descripcion="$1"
    local salida="$2"
    local esperado="$3"
    if printf '%s\n' "$salida" | grep -qxF -- "$(printf '%b' "$esperado")"; then
        echo "  ✅ ${descripcion}"
    else
        echo "  ❌ ${descripcion}: no aparece '${esperado}'"
        printf '%s\n' "$salida" | sed 's/^/     /'
        exit 1
    fi
}

echo "🧪 1/3 HDFS y YARN: nodos vivos"
DATANODES="$(en_master "hdfs dfsadmin -report 2>/dev/null | grep -oP 'Live datanodes \(\K[0-9]+'")"
NODEMANAGERS="$(en_master "yarn node -list 2>/dev/null | grep -oP 'Total Nodes:\K[0-9]+'")"
comprobar "DataNodes vivos = 3" "$DATANODES" "3"
comprobar "NodeManagers = 3" "$NODEMANAGERS" "3"

echo "🧪 2/3 wordcount en YARN (M01-YARN-01)"
SALIDA_WC="$(en_master "
    set -e
    hdfs dfs -mkdir -p ${BASE_HDFS}/entrada
    printf 'hola datos hola\n' | hdfs dfs -put -f - ${BASE_HDFS}/entrada/texto.txt
    hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar wordcount \
        ${BASE_HDFS}/entrada ${BASE_HDFS}/salida-wordcount >/dev/null 2>&1
    hdfs dfs -test -e ${BASE_HDFS}/salida-wordcount/_SUCCESS
    hdfs dfs -cat '${BASE_HDFS}/salida-wordcount/part-*'
")"
comprobar "datos = 1" "$SALIDA_WC" 'datos\t1'
comprobar "hola = 2" "$SALIDA_WC" 'hola\t2'

echo "🧪 3/3 Hadoop Streaming con Python (M01-MR-01)"
en_master "mkdir -p ${TRABAJO}"
$COMPOSE cp mapreduce/. "master:${TRABAJO}/" >/dev/null
$COMPOSE exec -T --user root master chown -R hadoop:hadoop "${TRABAJO}"
SALIDA_MR="$(en_master "
    set -e
    cd ${TRABAJO}
    hdfs dfs -mkdir -p ${BASE_HDFS}/ventas
    hdfs dfs -put -f ventas.csv ${BASE_HDFS}/ventas/ventas.csv
    hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.4.1.jar \
        -D mapreduce.job.reduces=1 \
        -files mapper_ventas.py,reducer_ventas.py \
        -input ${BASE_HDFS}/ventas/ventas.csv \
        -output ${BASE_HDFS}/salida-ventas \
        -mapper 'python3 mapper_ventas.py' \
        -reducer 'python3 reducer_ventas.py' >/dev/null 2>&1
    hdfs dfs -cat '${BASE_HDFS}/salida-ventas/part-*'
")"
comprobar "audio = 164.80" "$SALIDA_MR" 'audio\t164.80'
comprobar "perifericos = 75.00" "$SALIDA_MR" 'perifericos\t75.00'

echo "🧹 Limpiando ${BASE_HDFS} y ${TRABAJO}"
en_master "hdfs dfs -rm -r -f -skipTrash ${BASE_HDFS} >/dev/null; rm -rf ${TRABAJO}"

echo "✅ Prueba completada"
