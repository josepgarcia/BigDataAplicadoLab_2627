FROM apache/hive:4.0.1
USER root
RUN mkdir -p /opt/hive/data /opt/hive/trabajo /home/hive/.beeline \
    && chown -R hive:hive /opt/hive/data /opt/hive/trabajo /home/hive
USER hive
