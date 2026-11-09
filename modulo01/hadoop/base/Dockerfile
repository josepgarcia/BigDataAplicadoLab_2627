FROM --platform=linux/amd64 apache/hadoop:3.4.1 AS distribucion
FROM eclipse-temurin:11-jdk-jammy

ENV HADOOP_HOME=/opt/hadoop \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    JAVA_HOME=/opt/java/openjdk \
    PATH=/opt/hadoop/bin:/opt/hadoop/sbin:${PATH}

# Utilidades para el alumnado (sudo, editores, paginador, red).
# Entorno de laboratorio: hadoop puede usar sudo sin contraseña.
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl procps python3 \
    && apt-get install -y --no-install-recommends sudo vim nano less tree iputils-ping netcat-openbsd \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system hadoop \
    && useradd --create-home --shell /bin/bash --gid hadoop hadoop \
    && echo 'hadoop ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/hadoop \
    && chmod 0440 /etc/sudoers.d/hadoop \
    && mkdir -p /var/lib/hadoop/namenode /var/lib/hadoop/datanode /home/hadoop/trabajo \
    && chown -R hadoop:hadoop /var/lib/hadoop /home/hadoop/trabajo

COPY --from=distribucion --chown=hadoop:hadoop /opt/hadoop /opt/hadoop

# Silencia dos avisos sin efecto práctico en las órdenes de cliente:
# - NativeCodeLoader: las librerías nativas son amd64; en ARM (Mac Apple Silicon) se usa la versión Java.
# - DefaultNoHARMFailoverProxyProvider: "Connecting to ResourceManager..." en cada orden yarn/mapred.
RUN printf '\n# BDA: avisos silenciados\nlog4j.logger.org.apache.hadoop.util.NativeCodeLoader=ERROR\nlog4j.logger.org.apache.hadoop.yarn.client.DefaultNoHARMFailoverProxyProvider=WARN\n' \
    >> /opt/hadoop/etc/hadoop/log4j.properties

COPY entrypoint.sh /usr/local/bin/bda-hadoop-entrypoint
# Quita los CR por si el repo se clonó en Windows con finales CRLF (equivale a dos2unix)
RUN sed -i 's/\r$//' /usr/local/bin/bda-hadoop-entrypoint \
    && chmod 0755 /usr/local/bin/bda-hadoop-entrypoint

ENTRYPOINT ["/usr/local/bin/bda-hadoop-entrypoint"]
