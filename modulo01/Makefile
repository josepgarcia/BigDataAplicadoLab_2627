.PHONY: help build up down clean status report shell shell-root logs copiar-mapreduce test \
	hive-up hive-beeline hive-recorrido hive-logs hive-down hive-clean test-hive \
	formatos formatos-shell test-formatos \
	pg-up pg-psql pg-dump pg-restore pg-down pg-clean test-pg

# Autodetección de Docker Compose (V2 "docker compose" o V1 "docker-compose")
DOCKER_COMPOSE := $(shell \
	if docker compose version >/dev/null 2>&1; then echo "docker compose"; \
	elif command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; \
	else echo "docker compose"; fi)

# Git Bash (Windows) convierte rutas como /user/hive en C:/Program Files/Git/user/hive
# al pasarlas a docker; esto lo desactiva. Sin efecto en Linux, macOS ni WSL.
export MSYS_NO_PATHCONV := 1

HADOOP := $(DOCKER_COMPOSE) -f hadoop/compose.yaml
HIVE := $(DOCKER_COMPOSE) -f hive/compose.yaml
JDBC_HIVE := jdbc:hive2://localhost:10000/default
FORMATOS := $(DOCKER_COMPOSE) -f formatos/compose.yaml
PG := $(DOCKER_COMPOSE) -f postgres/compose.yaml
PG_DUMP := trabajo/bigdata-m01.sql

help: ## Mostrar esta ayuda
	@echo "Módulo 01 - Almacenamiento y ecosistema de datos (Hadoop: HDFS + YARN · Python formatos · PostgreSQL · Hive)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

build: ## Construir la imagen bda-m01-hadoop:3.4.1-r3
	@echo "🔨 Construyendo imagen..."
	$(HADOOP) build

up: ## Levantar el clúster (master + datanode1..3) y esperar a que esté sano
	@echo "🚀 Levantando clúster Hadoop (1 master + 3 workers)..."
	$(HADOOP) up -d --build --wait
	@echo "✅ Clúster listo"
	@echo "📊 HDFS (NameNode):      http://localhost:9870"
	@echo "📊 YARN (ResourceManager): http://localhost:8088"

down: ## Parar todos los servicios del módulo (conserva HDFS, el metastore y PostgreSQL)
	@echo "⏹️  Parando PostgreSQL, Hive y el clúster (los volúmenes se conservan)..."
	$(PG) down
	$(HIVE) down
	$(HADOOP) down

clean: ## Parar y BORRAR volúmenes: se pierden HDFS, el metastore de Hive y la base PostgreSQL
	@echo "⚠️  Se eliminan los volúmenes: NameNode formateado, datos HDFS, metastore de Hive y base PostgreSQL."
	$(PG) down -v
	$(HIVE) down -v
	$(HADOOP) down -v
	@echo "✅ Limpieza completada"

status: ## Ver estado de los contenedores
	@$(HADOOP) ps -a

report: ## Informe de HDFS (dfsadmin -report) y nodos YARN
	@$(HADOOP) exec --user hadoop master hdfs dfsadmin -report
	@$(HADOOP) exec --user hadoop master yarn node -list

shell: ## Abrir una shell en master como usuario hadoop
	$(HADOOP) exec --user hadoop master bash

shell-root: ## Abrir una shell en master como root (dentro de make shell también vale sudo)
	$(HADOOP) exec --user root master bash

logs: ## Ver los últimos registros de todos los servicios
	$(HADOOP) logs --tail=50

copiar-mapreduce: ## Copiar mapreduce/ a /home/hadoop/trabajo en master (bloque 04)
	$(HADOOP) exec --user hadoop master mkdir -p /home/hadoop/trabajo
	$(HADOOP) cp mapreduce/. master:/home/hadoop/trabajo/
	$(HADOOP) exec --user root master chown -R hadoop:hadoop /home/hadoop/trabajo
	@echo "✅ Ficheros en master:/home/hadoop/trabajo"

test: ## Prueba de humo: 3 nodos, wordcount en YARN y Streaming con Python
	@bash prueba.sh

hive-up: ## Bloque 07: preparar /user/hive en HDFS y levantar HiveServer2 (requiere make up)
	@echo "📦 Preparando directorios de Hive en HDFS (como hadoop)..."
	$(HADOOP) exec --user hadoop master hdfs dfs -mkdir -p /user/hive/warehouse /user/hive/external /tmp
	$(HADOOP) exec --user hadoop master hdfs dfs -chown -R hive /user/hive
	$(HADOOP) exec --user hadoop master hdfs dfs -chmod 1777 /tmp
	@echo "🚀 Levantando HiveServer2 (la primera vez descarga la imagen; en Apple Silicon va emulada)..."
	$(HIVE) up -d --build --wait
	@echo "✅ Hive listo · JDBC: $(JDBC_HIVE) · web: http://localhost:10002"

hive-beeline: ## Abrir Beeline en HiveServer2 (salir con !quit)
	$(HIVE) exec hiveserver2 beeline -u '$(JDBC_HIVE)' -n hive

hive-recorrido: ## Ejecutar hive/sql/recorrido.sql (crea o sobrescribe la base m01_empresa)
	$(HIVE) exec hiveserver2 beeline -u '$(JDBC_HIVE)' -n hive -f /sql/recorrido.sql

hive-logs: ## Ver los últimos registros de HiveServer2
	$(HIVE) logs --tail=80 hiveserver2

hive-down: ## Parar Hive (conserva el metastore; HDFS sigue activo)
	$(HIVE) down

hive-clean: ## Parar Hive y BORRAR el metastore Derby (los ficheros en HDFS no se borran)
	@echo "⚠️  Se borra el catálogo de Hive; los ficheros de /user/hive en HDFS se conservan."
	$(HIVE) down -v

test-hive: ## Prueba de humo de Hive: recorrido del bloque 07 en una base temporal
	@bash prueba-hive.sh

formatos: ## Bloque 05: ejecutar comparar_formatos.py (CSV → Parquet en trabajo/formatos/)
	$(FORMATOS) run --rm --build formatos python formatos/comparar_formatos.py

formatos-shell: ## Shell en el contenedor Python del bloque 05 (pandas, pyarrow, fastavro)
	$(FORMATOS) run --rm --build formatos bash

test-formatos: ## Prueba de humo del entorno Python: versiones, Parquet, ORC y Avro
	@$(FORMATOS) build -q
	@bash prueba-formatos.sh

pg-up: ## Bloque 06: levantar PostgreSQL + pgvector (contenedor postgres-vector)
	@echo "🚀 Levantando PostgreSQL + pgvector..."
	$(PG) up -d --wait
	@echo "✅ PostgreSQL listo en 127.0.0.1:5432 · base bigdata · usuario alumno"

pg-psql: ## Abrir psql como alumno en la base bigdata (salir con \q)
	$(PG) exec postgres psql -U alumno -d bigdata

pg-dump: ## Guardar la base bigdata en trabajo/bigdata-m01.sql
	@mkdir -p trabajo
	$(PG) exec -T postgres pg_dump -U alumno -d bigdata -f /tmp/bigdata-m01.sql
	$(PG) cp postgres:/tmp/bigdata-m01.sql $(PG_DUMP)
	@echo "✅ Copia en $(PG_DUMP)"

pg-restore: ## Cargar trabajo/bigdata-m01.sql en la base bigdata (sobre una base sin esas tablas)
	$(PG) cp $(PG_DUMP) postgres:/tmp/bigdata-m01.sql
	$(PG) exec -T postgres psql -U alumno -d bigdata -v ON_ERROR_STOP=1 -q -f /tmp/bigdata-m01.sql
	@echo "✅ Copia cargada desde $(PG_DUMP)"

pg-down: ## Parar PostgreSQL (conserva la base)
	$(PG) down

pg-clean: ## Parar PostgreSQL y BORRAR la base bigdata (guarda antes con make pg-dump)
	@echo "⚠️  Se borra el volumen de PostgreSQL: la base bigdata empieza vacía en el próximo pg-up."
	$(PG) down -v

test-pg: ## Prueba de humo de PostgreSQL: pgvector y vecino más próximo en una base temporal
	@bash prueba-postgres.sh
