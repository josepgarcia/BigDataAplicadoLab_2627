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
- Windows 11: ver [Uso en Windows 11](#uso-en-windows-11).

## Uso en Windows 11

### Opción recomendada: WSL2 + Docker Desktop

Para ejecutar estos laboratorios en Windows 11 se usa **WSL2 (Windows Subsystem for Linux 2)** con Docker Desktop.

#### 1. Instalar WSL2

```powershell
# En PowerShell como administrador
wsl --install
```

Esto instala Ubuntu por defecto. Reinicia el equipo si es necesario. Para elegir una versión concreta de Ubuntu:

```powershell
wsl.exe --install Ubuntu-22.04
```

#### 2. Instalar Docker Desktop

- Descárgalo desde [docker.com](https://www.docker.com/products/docker-desktop/).
- Durante la instalación, habilita la integración con WSL2.
- En Docker Desktop → Settings → Resources → WSL Integration, activa tu distribución Ubuntu.

#### 3. Configurar el entorno en WSL2

```bash
# Abrir la terminal de WSL (Ubuntu) e instalar las dependencias
sudo apt update
sudo apt install make git

# Clonar el repositorio
cd ~
git clone https://github.com/josepgarcia/BigDataAplicadoLab_2627.git
cd BigDataAplicadoLab_2627
```

#### 4. Ejecutar los comandos normalmente

```bash
cd modulo01
make up
make test
```

### Consideraciones importantes para Windows

- **Finales de línea**: Git en Windows puede convertir LF a CRLF. Configura Git para mantener LF:

  ```bash
  git config --global core.autocrlf input
  ```

  Si un script falla con `$'\r': command not found`, borra la copia y clona de nuevo desde la terminal de Ubuntu.

- **Rendimiento**: trabaja siempre dentro del sistema de archivos de WSL2 (`/home/usuario/...`) en lugar de `/mnt/c/...`.
- **Acceso a interfaces web**: las URL funcionan igual desde Windows (`localhost`).
- **PowerShell vs WSL**: ejecuta los comandos `make` desde la terminal WSL (Ubuntu), no desde PowerShell ni CMD.

### Alternativa: Git Bash (no recomendada)

Si prefieres no usar WSL2, puedes intentarlo con Git Bash, pero pueden surgir problemas de compatibilidad con los scripts bash y los permisos. WSL2 es la opción más robusta y compatible.

## Inicio rápido

```bash
git clone https://github.com/josepgarcia/BigDataAplicadoLab_2627.git
cd BigDataAplicadoLab_2627
```

Después, entrar en el directorio del módulo y seguir su `README.md`.

## Autor

Josep Garcia
