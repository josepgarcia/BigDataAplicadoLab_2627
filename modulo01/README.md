# Módulo 01 - Almacenamiento y ecosistema de datos

Clúster Hadoop 3.4.1 (HDFS + YARN) para los bloques **03 YARN** y **04 MapReduce** de M01, un entorno Python para el bloque **05 Formatos de datos**, PostgreSQL + pgvector para el bloque **06 PostgreSQL** y Hive 4.0.1 sobre el HDFS del clúster para el bloque **07 Hive**. Los bloques 01 y 02 se trabajan con la instalación manual descrita en los apuntes.

| Servicio | Procesos | Puertos en el anfitrión |
|---|---|---|
| `master` | NameNode, SecondaryNameNode, ResourceManager | 9870 (web HDFS), 8088 (web YARN), 9000 (RPC HDFS) |
| `datanode1`, `datanode2`, `datanode3` | DataNode + NodeManager | — |
| `formatos` (bloque 05, aparte) | Python 3.12 con pandas, pyarrow y fastavro (se usa y se borra) | — |
| `postgres-vector` (bloque 06, aparte) | PostgreSQL 17 + pgvector 0.8.1 | 5432 |
| `hiveserver2` (bloque 07, aparte) | HiveServer2 + metastore Derby | 10000 (JDBC), 10002 (web Hive) |

- Imagen `bda-m01-hadoop:3.4.1-r3`: Java 11, Hadoop 3.4.1 y Python 3 (para Hadoop Streaming).
- Réplica HDFS 3. Cada nodo guarda sus datos en un volumen propio.
- Sin SSH: cada contenedor arranca sus procesos según `HADOOP_ROLE`. El NameNode se formatea solo la primera vez.
- Puertos publicados solo en `127.0.0.1`.

## Requisitos

- Docker y Docker Compose v2.
- Make (opcional: todas las órdenes tienen su equivalente `docker compose`). En Windows, desde la terminal de Ubuntu (WSL2): `sudo apt install -y make`; ver [Uso en Windows 11](../README.md#uso-en-windows-11).
- **Memoria**: el clúster ocupa unos 3,2 GB en reposo y unos 3,6 GB ejecutando un trabajo. En Docker Desktop asigna al menos 6 GB (Settings → Resources).
- Los puertos 9870, 8088 y 9000 deben estar libres (5432 para PostgreSQL; 10000 y 10002 para Hive). Para el contenedor de los bloques 01–02 antes de empezar:

```bash
docker stop --time 45 hadoop-manual
```

## Uso

Desde esta carpeta (`modulo01/`):

```bash
make up        # construye la imagen, levanta los 4 servicios y espera a que estén sanos
make report    # hdfs dfsadmin -report + yarn node -list
make shell     # shell en master como usuario hadoop
make test      # prueba de humo: 3 nodos, wordcount en YARN y Streaming con Python
make down      # para todos los servicios del módulo (clúster, Hive, PostgreSQL) conservando los datos
make help      # todas las opciones
```

Equivalentes sin Make:

```bash
docker compose -f hadoop/compose.yaml up -d --build --wait
docker compose -f hadoop/compose.yaml exec --user hadoop master hdfs dfsadmin -report
docker compose -f hadoop/compose.yaml exec --user hadoop master yarn node -list
docker compose -f hadoop/compose.yaml exec --user hadoop master bash
docker compose -f hadoop/compose.yaml down
```

`up --wait` termina cuando los cuatro servicios están sanos. Un worker solo se considera sano si su DataNode y su NodeManager responden **y** el NameNode ha salido del modo seguro, de modo que HDFS ya admite escrituras.

Interfaces web: HDFS en <http://localhost:9870> y YARN en <http://localhost:8088>. Los enlaces internos (`master`, `datanode1`…) que aparecen en ellas no se resuelven desde el navegador del anfitrión.

### Subir ficheros a HDFS

La interfaz web sirve para **consultar** HDFS. Subir desde *Utilities → Browse the file system* falla con `Couldn't upload the file`, por dos motivos:

- WebHDFS redirige el contenido al DataNode (`http://datanodeN:9864/...`). Ese nombre y ese puerto solo existen dentro de la red de Docker: el navegador no los alcanza.
- La web actúa como el usuario anónimo `dr.who`, que no tiene permiso de escritura en HDFS (`/` pertenece a `hadoop`, 755). Se mantienen los permisos HDFS a propósito.

Para subir un fichero del anfitrión, primero cópialo al contenedor y después súbelo a HDFS como `hadoop`:

```bash
docker compose -f hadoop/compose.yaml cp mi-fichero.csv master:/tmp/
docker compose -f hadoop/compose.yaml exec --user hadoop master hdfs dfs -mkdir -p /datos
docker compose -f hadoop/compose.yaml exec --user hadoop master hdfs dfs -put /tmp/mi-fichero.csv /datos/
```

Después el fichero aparece en el explorador web.

### Ficheros del bloque 04 (MapReduce)

`mapreduce/` contiene los CSV de práctica y los scripts `mapper_ventas.py` / `reducer_ventas.py`. Para copiarlos a `master:/home/hadoop/trabajo`:

```bash
make copiar-mapreduce
```

### Formatos de datos (bloque 05)

La práctica de Python no necesita Python en el equipo: se ejecuta en un contenedor de usar y tirar (`formatos/compose.yaml`, imagen `bda-m01-formatos:3.12-r1`) con Python 3.12.8, pandas 2.2.3, pyarrow 18.1.0 (Parquet y ORC) y fastavro 1.10.0 (Avro). No depende del clúster Hadoop.

El contenedor monta esta carpeta (`modulo01/`) en `/lab`: lee `mapreduce/ventas.csv` y escribe los resultados en `trabajo/formatos/`, que aparecen también en el anfitrión. `trabajo/` está ignorado por Git.

```bash
make formatos        # ejecuta formatos/comparar_formatos.py (CSV → Parquet, esquema, lectura selectiva)
make formatos-shell  # shell en /lab con python, pandas, pyarrow y fastavro
make test-formatos   # prueba de humo: versiones, Parquet, ORC y Avro
```

Equivalentes sin Make:

```bash
docker compose -f formatos/compose.yaml run --rm --build formatos python formatos/comparar_formatos.py
docker compose -f formatos/compose.yaml run --rm --build formatos bash
```

Dentro de la shell, `python` abre el intérprete y `python fichero.py` ejecuta un programa. Lo que se guarde fuera de `/lab` se pierde al salir.

### PostgreSQL + pgvector (bloque 06)

PostgreSQL 17 con la extensión pgvector (`postgres/compose.yaml`, imagen `pgvector/pgvector:0.8.1-pg17`), independiente del clúster. El contenedor se llama `postgres-vector`, así que las órdenes `docker exec postgres-vector ...` de los apuntes funcionan tal cual. Credenciales solo para el laboratorio: usuario `alumno`, contraseña `alumno`, base `bigdata`. La base **se conserva** en un volumen entre sesiones.

```bash
make pg-up       # levanta PostgreSQL y espera a que acepte conexiones
make pg-psql     # psql como alumno en bigdata (salir con \q)
make pg-dump     # guarda la base en trabajo/bigdata-m01.sql
make pg-restore  # carga trabajo/bigdata-m01.sql en una base nueva (tras pg-clean)
make test-pg     # prueba de humo en una base temporal (no toca bigdata)
make pg-down     # para PostgreSQL y conserva la base
make pg-clean    # ⚠️ borra la base: guarda antes con make pg-dump
```

Equivalentes sin Make:

```bash
docker compose -f postgres/compose.yaml up -d --wait
docker exec -it postgres-vector psql -U alumno -d bigdata
docker exec postgres-vector pg_dump -U alumno -d bigdata -f /tmp/bigdata-m01.sql
docker cp postgres-vector:/tmp/bigdata-m01.sql ./bigdata-m01.sql
docker compose -f postgres/compose.yaml down
```

Si el puerto 5432 está ocupado por un PostgreSQL instalado en el equipo, para ese servicio o cambia el puerto del anfitrión en `postgres/compose.yaml` (p. ej. `"127.0.0.1:5433:5432"`). Las órdenes con `docker exec` no usan ese puerto.

### Hive (bloque 07)

Hive es un Compose aparte (`hive/compose.yaml`, proyecto `m01-hive`) que se une a la red del clúster (`m01-yarn_default`): **levanta antes el clúster** con `make up`. Guarda las tablas en HDFS (`/user/hive/...`) y el catálogo en un metastore Derby con volumen propio. Las consultas se ejecutan con **MapReduce local dentro de HiveServer2**, no en YARN: en este bloque se estudian SQL y almacenamiento.

```bash
make up              # clúster Hadoop (si no está levantado)
make hive-up         # prepara /user/hive y /tmp en HDFS y levanta HiveServer2
make hive-beeline    # Beeline en HiveServer2 (salir con !quit)
make hive-recorrido  # ejecuta hive/sql/recorrido.sql: crea o sobrescribe la base m01_empresa
make test-hive       # prueba de humo en una base temporal (no toca m01_empresa)
make hive-down       # para Hive y conserva el catálogo
```

Equivalentes sin Make:

```bash
docker compose -f hadoop/compose.yaml exec --user hadoop master hdfs dfs -mkdir -p /user/hive/warehouse /user/hive/external /tmp
docker compose -f hadoop/compose.yaml exec --user hadoop master hdfs dfs -chown -R hive /user/hive
docker compose -f hadoop/compose.yaml exec --user hadoop master hdfs dfs -chmod 1777 /tmp
docker compose -f hive/compose.yaml up -d --build --wait
docker compose -f hive/compose.yaml exec hiveserver2 beeline -u 'jdbc:hive2://localhost:10000/default' -n hive
docker compose -f hive/compose.yaml logs --tail=80 hiveserver2
docker compose -f hive/compose.yaml down
```

- **Apple Silicon**: la imagen oficial `apache/hive:4.0.1` solo existe para amd64 y se ejecuta emulada. Funciona, pero tarda más en arrancar (el `healthcheck` puede llevar 1–2 minutos) y la primera vez descarga cerca de 1 GB.
- **Memoria**: HiveServer2 ocupa alrededor de 1 GB (límite 2 GB) además del clúster.
- `hive/datos/` se monta en `/datos-entrada` (solo lectura) y `hive/sql/` en `/sql`.
- **Orden de parada**: primero Hive y después el clúster. `make down` ya lo hace así.
- Derby y HDFS son almacenes distintos: `make hive-clean` borra el catálogo pero **no** los ficheros de `/user/hive` en HDFS, y `make clean` borra ambos.
- Ajustes de `hive/conf/hive-site.xml` propios del laboratorio: tablas gestionadas clásicas no ACID (transformador de metadatos vacío, HIVE-28198) y sin conversión automática a map-join (HIVE-13764). El valor del transformador es un espacio (`<value> </value>`), no un elemento vacío. Tras cambiar la configuración: `make hive-down hive-up`.

## Estructura

```
modulo01/
├── Makefile
├── prueba.sh             # prueba de humo (make test)
├── prueba-hive.sh        # prueba de humo de Hive (make test-hive)
├── prueba-formatos.sh    # prueba de humo del entorno Python (make test-formatos)
├── prueba-postgres.sh    # prueba de humo de PostgreSQL (make test-pg)
├── trabajo/              # resultados del alumnado (ignorado por Git; se crea al usarlo)
├── formatos/
│   ├── compose.yaml      # proyecto m01-formatos (contenedor de usar y tirar)
│   ├── Dockerfile        # python:3.12.8-slim + requirements.txt
│   ├── requirements.txt  # pandas, numpy, pyarrow y fastavro con versión fija
│   └── comparar_formatos.py
├── postgres/
│   └── compose.yaml      # proyecto m01-postgres, contenedor postgres-vector
├── hadoop/
│   ├── compose.yaml      # proyecto m01-yarn
│   ├── base/             # Dockerfile + entrypoint.sh (arranque por roles)
│   └── conf/             # core-site, hdfs-site, mapred-site, yarn-site (montados en solo lectura)
├── hive/
│   ├── compose.yaml      # proyecto m01-hive, red externa m01-yarn_default
│   ├── Dockerfile        # apache/hive:4.0.1 + directorios de trabajo
│   ├── conf/             # core-site, hive-site, mapred-site (montados en solo lectura)
│   ├── datos/            # empleados.csv → /datos-entrada
│   └── sql/              # recorrido.sql → /sql
└── mapreduce/            # datos y scripts del bloque 04
```

Si cambias algo en `hadoop/conf/`, recrea los servicios con `make down && make up`. Si cambias `hadoop/base/`, `make up` reconstruye la imagen.

## Comportamientos que conviene conocer

- **Modo seguro tras reiniciar**: al arrancar, el NameNode espera los informes de bloques de los DataNodes. Durante ese tiempo HDFS es de solo lectura (`Name node is in safe mode`). `up --wait` ya lo espera. Si arrancas servicios a mano, comprueba el estado con `hdfs dfsadmin -safemode get`.
- **Leer con un DataNode parado** (M01-HDFS-07): justo después de `docker compose stop datanode2`, el NameNode todavía lo da por vivo. El cliente intenta primero esa réplica y espera unos **60 s** (`dfs.client.socket-timeout`), mostrando un `ConnectTimeoutException` antes de leer de otra réplica. El contenido se obtiene igualmente: la traza es parte de lo que se observa.
- **Subreplicación** (M01-HDFS-06): con dos DataNodes, un fichero con réplica 3 se escribe igualmente, pero `fsck` lo marca como *Under-replicated*. Al añadir `datanode3`, `hdfs dfs -setrep -w 3` espera a que tenga las tres copias.

## Qué demuestra y qué no

Este clúster permite observar la mecánica real de HDFS y YARN: reparto de bloques y réplicas, incorporación de nodos, lectura con un nodo caído y planificación de tareas en NodeManagers.

Los cuatro contenedores comparten CPU, memoria y disco del mismo equipo. Por tanto, el laboratorio **no** demuestra:

- aumento real de capacidad ni de rendimiento al añadir nodos;
- tolerancia a la caída del equipo anfitrión o del disco físico;
- alta disponibilidad del NameNode, que aquí es un punto único de fallo;
- ganancia de tamaño o velocidad de Parquet frente a CSV: con una muestra de tres filas, Parquet ocupa más por sus metadatos;
- rendimiento de búsqueda vectorial: los vectores de práctica tienen 3 dimensiones inventadas, no salen de un modelo de *embeddings*;
- rendimiento de Hive ni ejecución distribuida de sus consultas: usa MapReduce local y un metastore Derby de una sola instancia (en producción, un metastore compartido con MySQL o PostgreSQL).

## Limpieza

```bash
make clean   # docker compose down -v (PostgreSQL, Hive y clúster)
```

⚠️ Borra los volúmenes: se pierden el NameNode formateado, todos los ficheros de HDFS, el catálogo de Hive y la base PostgreSQL. `trabajo/` no se toca. No lo uses para diagnosticar problemas; usa antes `make down` y `make up`.
