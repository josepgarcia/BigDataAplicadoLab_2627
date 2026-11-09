#!/usr/bin/env bash
set -euo pipefail

run_as_hadoop() {
  su -s /bin/bash hadoop -c "$*"
}

prepare_storage() {
  mkdir -p /var/lib/hadoop/namenode /var/lib/hadoop/datanode
  chown -R hadoop:hadoop /var/lib/hadoop
}

format_namenode_if_needed() {
  if [ ! -f /var/lib/hadoop/namenode/current/VERSION ]; then
    run_as_hadoop "${HADOOP_HOME}/bin/hdfs namenode -format -force -nonInteractive"
  fi
}

start_single_hdfs() {
  format_namenode_if_needed
  run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon start namenode"
  run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon start datanode"
  run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon start secondarynamenode"
}

start_master() {
  format_namenode_if_needed
  run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon start namenode"
  run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon start secondarynamenode"
  run_as_hadoop "${HADOOP_HOME}/bin/yarn --daemon start resourcemanager"
}

start_worker() {
  run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon start datanode"
  run_as_hadoop "${HADOOP_HOME}/bin/yarn --daemon start nodemanager"
}

stop_services() {
  case "${HADOOP_ROLE:-}" in
    hdfs-single)
      run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon stop secondarynamenode || true"
      run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon stop datanode || true"
      run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon stop namenode || true"
      ;;
    master)
      run_as_hadoop "${HADOOP_HOME}/bin/yarn --daemon stop resourcemanager || true"
      run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon stop secondarynamenode || true"
      run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon stop namenode || true"
      ;;
    worker)
      run_as_hadoop "${HADOOP_HOME}/bin/yarn --daemon stop nodemanager || true"
      run_as_hadoop "${HADOOP_HOME}/bin/hdfs --daemon stop datanode || true"
      ;;
  esac
}

prepare_storage

case "${HADOOP_ROLE:-}" in
  hdfs-single) start_single_hdfs ;;
  master) start_master ;;
  worker) start_worker ;;
  *)
    echo "HADOOP_ROLE debe ser hdfs-single, master o worker." >&2
    exit 64
    ;;
esac

trap stop_services TERM INT
tail -f /dev/null &
wait $!
