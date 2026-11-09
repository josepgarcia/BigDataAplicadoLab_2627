.PHONY: help build up down clean status report shell logs copiar-mapreduce test

# Autodetección de Docker Compose (V2 "docker compose" o V1 "docker-compose")
DOCKER_COMPOSE := $(shell \
	if docker compose version >/dev/null 2>&1; then echo "docker compose"; \
	elif command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; \
	else echo "docker compose"; fi)

HADOOP := $(DOCKER_COMPOSE) -f hadoop/compose.yaml

help: ## Mostrar esta ayuda
	@echo "Módulo 01 - Almacenamiento y ecosistema de datos (Hadoop: HDFS + YARN)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

build: ## Construir la imagen bda-m01-hadoop:3.4.1-r2
	@echo "🔨 Construyendo imagen..."
	$(HADOOP) build

up: ## Levantar el clúster (master + datanode1..3) y esperar a que esté sano
	@echo "🚀 Levantando clúster Hadoop (1 master + 3 workers)..."
	$(HADOOP) up -d --build --wait
	@echo "✅ Clúster listo"
	@echo "📊 HDFS (NameNode):      http://localhost:9870"
	@echo "📊 YARN (ResourceManager): http://localhost:8088"

down: ## Parar y eliminar contenedores (conserva los datos HDFS)
	@echo "⏹️  Parando clúster (los volúmenes se conservan)..."
	$(HADOOP) down

clean: ## Parar y BORRAR volúmenes: se pierden HDFS y sus ficheros
	@echo "⚠️  Se eliminan los volúmenes: NameNode formateado y datos HDFS."
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
