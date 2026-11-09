#!/bin/bash
# Prueba de humo del entorno Python del bloque 05: versiones, CSV → Parquet con
# comparar_formatos.py y escritura/lectura de ORC y Avro en un directorio temporal.
# Se ejecuta en el ANFITRIÓN. Deja trabajo/formatos/ventas.parquet (lo mismo que make formatos).

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

FORMATOS="docker compose -f formatos/compose.yaml run --rm -T formatos"

comprobar() {
    local descripcion="$1"
    local salida="$2"
    local esperado="$3"
    if printf '%s\n' "$salida" | grep -qF -- "$esperado"; then
        echo "  ✅ ${descripcion}"
    else
        echo "  ❌ ${descripcion}: no aparece '${esperado}'"
        printf '%s\n' "$salida" | sed 's/^/     /'
        exit 1
    fi
}

echo "🧪 1/3 Versiones de Python y bibliotecas"
VERSIONES="$($FORMATOS python -c 'import sys, pandas, pyarrow, fastavro; print(sys.version.split()[0], pandas.__version__, pyarrow.__version__, fastavro.__version__)')"
comprobar "Python 3.12 · pandas 2.2.3 · pyarrow 18.1.0 · fastavro 1.10.0" "$VERSIONES" "3.12.8 2.2.3 18.1.0 1.10.0"

echo "🧪 2/3 CSV → Parquet (comparar_formatos.py)"
SALIDA="$($FORMATOS python formatos/comparar_formatos.py)"
comprobar "3 filas" "$SALIDA" "filas: 3"
comprobar "recorrido completo" "$SALIDA" "recorrido completo: correcto"
comprobar "audio = 164.80" "$SALIDA" "audio: 164.80"
comprobar "perifericos = 75.00" "$SALIDA" "perifericos: 75.00"

echo "🧪 3/3 ORC y Avro (directorio temporal del contenedor)"
SALIDA="$($FORMATOS python - <<'PY'
import tempfile
from pathlib import Path
import pandas as pd
import pyarrow as pa
import pyarrow.orc as orc
from fastavro import parse_schema, reader, writer

ventas = pd.read_csv("mapreduce/ventas.csv")
with tempfile.TemporaryDirectory() as tmp:
    ruta_orc = Path(tmp) / "ventas.orc"
    orc.write_table(pa.Table.from_pandas(ventas, preserve_index=False), ruta_orc)
    print("orc filas:", orc.read_table(ruta_orc).num_rows)

    esquema = parse_schema({"type": "record", "name": "Venta", "fields": [
        {"name": "producto", "type": "string"}, {"name": "categoria", "type": "string"},
        {"name": "unidades", "type": "int"}, {"name": "precio", "type": "double"}]})
    ruta_avro = Path(tmp) / "ventas.avro"
    with open(ruta_avro, "wb") as f:
        writer(f, esquema, ventas.to_dict("records"))
    with open(ruta_avro, "rb") as f:
        print("avro filas:", sum(1 for _ in reader(f)))
PY
)"
comprobar "ORC: 3 filas" "$SALIDA" "orc filas: 3"
comprobar "Avro: 3 filas" "$SALIDA" "avro filas: 3"

echo "✅ Prueba de formatos completada"
