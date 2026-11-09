FROM --platform=linux/amd64 apache/hadoop:3.4.1 AS distribucion
FROM eclipse-temurin:11-jdk-jammy

ENV HADOOP_HOME=/opt/hadoop \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    JAVA_HOME=/opt/java/openjdk \
    PATH=/opt/hadoop/bin:/opt/hadoop/sbin:${PATH}

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl procps python3 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system hadoop \
    && useradd --create-home --shell /bin/bash --gid hadoop hadoop \
    && mkdir -p /var/lib/hadoop/namenode /var/lib/hadoop/datanode /home/hadoop/trabajo \
    && chown -R hadoop:hadoop /var/lib/hadoop /home/hadoop/trabajo

COPY --from=distribucion --chown=hadoop:hadoop /opt/hadoop /opt/hadoop

COPY entrypoint.sh /usr/local/bin/bda-hadoop-entrypoint
RUN chmod 0755 /usr/local/bin/bda-hadoop-entrypoint

ENTRYPOINT ["/usr/local/bin/bda-hadoop-entrypoint"]
