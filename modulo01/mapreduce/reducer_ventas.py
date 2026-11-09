#!/usr/bin/env python3
"""Suma pares categoria/importe previamente ordenados por categoria."""
import sys
from decimal import Decimal

clave_actual = None
total = Decimal('0')

for linea in sys.stdin:
    clave, importe = linea.rstrip().split('\t', 1)
    if clave != clave_actual and clave_actual is not None:
        print(f'{clave_actual}\t{total:.2f}')
        total = Decimal('0')
    clave_actual = clave
    total += Decimal(importe)

if clave_actual is not None:
    print(f'{clave_actual}\t{total:.2f}')
