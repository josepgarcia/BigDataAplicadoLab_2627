#!/usr/bin/env python3
"""Ejemplo de M01 (bloque 05): conversión CSV → Parquet, esquema y lectura selectiva."""

from pathlib import Path
from time import perf_counter

import pandas as pd
import pyarrow.parquet as pq


raiz = Path(__file__).resolve().parents[1]  # modulo01/ (en el contenedor, /lab)
entrada = raiz / "mapreduce/ventas.csv"
destino = raiz / "trabajo/formatos/ventas.parquet"
destino.parent.mkdir(parents=True, exist_ok=True)

inicio = perf_counter()
ventas = pd.read_csv(
    entrada,
    dtype={"producto": "string", "categoria": "string", "unidades": "int64", "precio": "float64"},
)
ventas["importe"] = (ventas["unidades"] * ventas["precio"]).round(2)
ventas.to_parquet(destino, engine="pyarrow", compression="snappy", index=False)
segundos = perf_counter() - inicio

recuperadas = pd.read_parquet(destino)
pd.testing.assert_frame_equal(ventas, recuperadas)
selectiva = pd.read_parquet(destino, columns=["categoria", "importe"])
totales = selectiva.groupby("categoria")["importe"].sum()

print(f"Entrada sintética: {entrada.name}; filas: {len(ventas)}")
print(pq.read_schema(destino))
print(f"CSV: {entrada.stat().st_size} bytes; Parquet: {destino.stat().st_size} bytes")
print(f"Conversión: {segundos:.6f} segundos; recorrido completo: correcto")
for categoria, importe in totales.items():
    print(f"{categoria}: {importe:.2f}")
