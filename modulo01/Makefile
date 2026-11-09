.PHONY: help build up down clean status report shell logs copiar-mapreduce test \
	hive-up hive-beeline hive-recorrido hive-logs hive-down hive-clean test-hive

# Autodetección de Docker Compose (V2 "docker compose" o V1 "docker-compose")
DOCKER_COMPOSE := $(shell \
	if docker compose version >/dev/null 2>&1; then echo "docker compose"; \
	elif command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; \
	else echo "docker compose"; fi)

HADOOP := $(DOCKER_COMPOSE) -f hadoop/compose.yaml
HIVE := $(DOCKER_COMPOSE) -f hive/compose.yaml
JDBC_HIVE := jdbc:hive2://localhost:10000/default

help: ## Mostrar esta ayuda
	@echo "Módulo 01 - Almacenamiento y ecosistema de datos (Hadoop: HDFS + YARN · Hive)"
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

down: ## Parar Hive (si está activo) y el clúster (conserva HDFS y el metastore)
	@echo "⏹️  Parando Hive y el clúster (los volúmenes se conservan)..."
	$(HIVE) down
	$(HADOOP) down

clean: ## Parar y BORRAR volúmenes: se pierden HDFS, sus ficheros y el metastore de Hive
	@echo "⚠️  Se eliminan los volúmenes: NameNode formateado, datos HDFS y metastore de Hive."
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
