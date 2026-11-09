CREATE DATABASE IF NOT EXISTS m01_empresa;
USE m01_empresa;
CREATE TABLE IF NOT EXISTS empleados_texto (
  nombre STRING, departamento STRING, salario DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('transactional'='false');
LOAD DATA LOCAL INPATH '/datos-entrada/empleados.csv'
OVERWRITE INTO TABLE empleados_texto;
SELECT COUNT(*) AS filas FROM empleados_texto;
SELECT departamento, COUNT(*) AS personas, AVG(salario) AS salario_medio
FROM empleados_texto GROUP BY departamento ORDER BY departamento;
CREATE EXTERNAL TABLE IF NOT EXISTS empleados_ext (
  nombre STRING, departamento STRING, salario DOUBLE
)
STORED AS PARQUET
LOCATION '/user/hive/external/empleados_parquet'
TBLPROPERTIES ('external.table.purge'='false');
INSERT OVERWRITE TABLE empleados_ext SELECT * FROM empleados_texto;
SELECT COUNT(*) AS filas_parquet FROM empleados_ext;
CREATE TABLE IF NOT EXISTS departamentos (
  departamento STRING, responsable STRING
) STORED AS TEXTFILE TBLPROPERTIES ('transactional'='false');
INSERT OVERWRITE TABLE departamentos VALUES
('datos','Eva'),('infraestructura','Luis');
SELECT e.nombre, d.responsable
FROM empleados_ext e LEFT JOIN departamentos d
ON e.departamento=d.departamento ORDER BY e.nombre;
CREATE EXTERNAL TABLE IF NOT EXISTS ventas_por_fecha (
  producto STRING, categoria STRING, importe DECIMAL(12,2)
)
PARTITIONED BY (fecha DATE)
STORED AS PARQUET
LOCATION '/user/hive/external/ventas_por_fecha'
TBLPROPERTIES ('external.table.purge'='false');
INSERT OVERWRITE TABLE ventas_por_fecha PARTITION(fecha='2026-10-22')
SELECT 'teclado','perifericos',CAST(75.00 AS DECIMAL(12,2));
SHOW PARTITIONS ventas_por_fecha;
SELECT fecha, SUM(importe) AS total
FROM ventas_por_fecha WHERE fecha='2026-10-22' GROUP BY fecha;
DESCRIBE FORMATTED empleados_ext;
