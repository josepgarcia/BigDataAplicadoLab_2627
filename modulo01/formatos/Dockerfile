# Entorno Python del bloque 05: pandas + pyarrow (Parquet y ORC) + fastavro (Avro).
# Evita depender del Python instalado en el equipo del alumnado.
FROM python:3.12.8-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt \
    && useradd --create-home --uid 1000 --shell /bin/bash alumno

USER alumno
WORKDIR /lab
CMD ["bash"]
