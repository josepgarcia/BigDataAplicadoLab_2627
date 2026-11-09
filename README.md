```
 ____  ____    _      _           _
| __ )|  _ \  / \    | |    __ _ | |__
|  _ \| | | |/ _ \   | |   / _` || '_ \
| |_) | |_| / ___ \  | |__| (_| || |_) |
|____/|____/_/   \_\ |_____\__,_||_.__/
                                2026/27
```

# Big Data Aplicado - Laboratorio 2026/27

Entornos Docker para las prácticas de la asignatura Big Data Aplicado (Curso de Especialización en Inteligencia Artificial y Big Data, curso 2026/2027).

Los laboratorios se irán añadiendo a medida que avance la asignatura, un directorio por módulo.

## Módulos

| Módulo | Contenido | Laboratorio |
|---|---|---|
| [modulo01](modulo01/README.md) | Almacenamiento y ecosistema de datos | Clúster Hadoop 3.4.1: HDFS + YARN, 1 master + 3 workers (bloques 03–04) · Python para formatos (05) · PostgreSQL + pgvector (06) · Hive 4.0.1 (07) |

## Requisitos

- Docker y Docker Compose
- Make
- `wget` (macOS: `brew install wget`)
- Windows 11: usar WSL2 (Ubuntu) + Docker Desktop con integración WSL activada. Ejecutar los comandos desde la terminal de WSL y configurar `git config --global core.autocrlf input` para conservar los finales de línea LF.

## Inicio rápido

```bash
git clone https://github.com/josepgarcia/BigDataAplicadoLab_2627.git
cd BigDataAplicadoLab_2627
```

Después, entrar en el directorio del módulo y seguir su `README.md`.

## Autor

Josep Garcia
