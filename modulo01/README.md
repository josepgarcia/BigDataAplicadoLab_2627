# Módulo 01 - Almacenamiento y ecosistema de datos

Clúster Hadoop 3.4.1 (HDFS + YARN) para los bloques **03 YARN** y **04 MapReduce** de M01. Los bloques 01 y 02 se trabajan con la instalación manual descrita en los apuntes.

| Servicio | Procesos | Puertos en el anfitrión |
|---|---|---|
| `master` | NameNode, SecondaryNameNode, ResourceManager | 9870 (web HDFS), 8088 (web YARN), 9000 (RPC HDFS) |
| `datanode1`, `datanode2`, `datanode3` | DataNode + NodeManager | — |

- Imagen `bda-m01-hadoop:3.4.1-r3`: Java 11, Hadoop 3.4.1 y Python 3 (para Hadoop Streaming).
- Réplica HDFS 3. Cada nodo guarda sus datos en un volumen propio.
- Sin SSH: cada contenedor arranca sus procesos según `HADOOP_ROLE`. El NameNode se formatea solo la primera vez.
- Puertos publicados solo en `127.0.0.1`.

## Requisitos

- Docker y Docker Compose v2.
- Make (opcional: todas las órdenes tienen su equivalente `docker compose`).
- **Memoria**: el clúster ocupa unos 3,2 GB en reposo y unos 3,6 GB ejecutando un trabajo. En Docker Desktop asigna al menos 6 GB (Settings → Resources).
- Los puertos 9870, 8088 y 9000 deben estar libres. Para el contenedor de los bloques 01–02 antes de empezar:

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
make down      # para el clúster conservando los datos
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

## Estructura

```
modulo01/
├── Makefile
├── prueba.sh             # prueba de humo (make test)
├── hadoop/
│   ├── compose.yaml      # proyecto m01-yarn
│   ├── base/             # Dockerfile + entrypoint.sh (arranque por roles)
│   └── conf/             # core-site, hdfs-site, mapred-site, yarn-site (montados en solo lectura)
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
- alta disponibilidad del NameNode, que aquí es un punto único de fallo.

## Limpieza

```bash
make clean   # docker compose down -v
```

⚠️ Borra los volúmenes: se pierden el NameNode formateado y todos los ficheros de HDFS. No lo uses para diagnosticar problemas; usa antes `make down` y `make up`.
