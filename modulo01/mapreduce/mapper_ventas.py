#!/usr/bin/env python3
"""Emite pares categoria/importe a partir del CSV docente de ventas."""
import csv
import sys
from decimal import Decimal, InvalidOperation

for fila in csv.reader(sys.stdin):
    if not fila or fila[0] == 'producto':
        continue
    try:
        producto, categoria, unidades, precio = fila
        cantidad = int(unidades)
        precio_unitario = Decimal(precio)
        if (cantidad < 0 or not precio_unitario.is_finite()
                or precio_unitario < 0 or not categoria):
            raise ValueError('venta no valida')
        print(f'{categoria}\t{cantidad * precio_unitario:.2f}')
    except (ValueError, InvalidOperation) as error:
        print(f'Fila descartada: {fila!r}; {error}', file=sys.stderr)
        continue
