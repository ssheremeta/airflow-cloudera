#!/bin/bash

set -ex

chmod u+x $CONF_DIR/scripts/*.sh
chown -R airflow: $CONF_DIR/logs
chown -R airflow: $CONF_DIR/airflow-conf
#setfacl -R -m u:airflow:rwx $CONF_DIR

mkdir -p /var/log/airflow
chown -R airflow: /var/log/airflow

source $CONF_DIR/scripts/common.sh

SERVICE=${1}
log "Running Airflow CSD control script..."
log "Got command as $SERVICE"

export AIRFLOW_HOME="$CONF_DIR/airflow-conf"
export PATH=$AIRFLOW_CONDA_HOME/bin:$PATH
export AIRFLOW_CONFIG="$AIRFLOW_HOME/airflow.cfg"
if [[ -e $AIRFLOW_HOME/airflow-env.sh ]]; then
    source $AIRFLOW_HOME/airflow-env.sh
fi
export PYTHONPATH=$PYTHONPATH:$AIRFLOW_HOME


case ${SERVICE} in
  (webserver_initdb)
    log "Initialising the Airflow metadata DB"
    substitute_common_tokens
    substitute_webserver_tokens
    exec su airflow -c "airflow initdb" >> ${CONF_DIR}/logs/stdout.log 2>> ${CONF_DIR}/logs/stderr.log
    ;;
  (webserver_start)
    log "Starting the Airflow webserver"
    substitute_common_tokens
    substitute_webserver_tokens
    exec su airflow -c "airflow webserver" >> ${CONF_DIR}/logs/stdout.log 2>> ${CONF_DIR}/logs/stderr.log
    ;;
  (celery_start)
    log "Starting the Airflow celery"
    substitute_common_tokens
    substitute_celery_tokens
    exec su airflow -c "airflow flower" >> ${CONF_DIR}/logs/stdout.log 2>> ${CONF_DIR}/logs/stderr.log
    ;;
  (worker_start)
    log "Starting the Airflow worker"
    substitute_common_tokens
    exec su airflow -c "airflow worker -q ${WORKER__QUEUE}" >> ${CONF_DIR}/logs/stdout.log 2>> ${CONF_DIR}/logs/stderr.log
    ;;
  (scheduler_start)
    log "Starting the Airflow scheduler"
    substitute_common_tokens
    substitute_scheduler_tokens
    exec su airflow -c "airflow scheduler" >> ${CONF_DIR}/logs/stdout.log 2>> ${CONF_DIR}/logs/stderr.log
    ;;
  (worker_pip_install)
    log "Installing additional python packages by pip"
    pip install -r ${CONF_DIR}/airflow-conf/requirements.txt >> ${CONF_DIR}/logs/stdout.log 2>> ${CONF_DIR}/logs/stderr.log
    ;;
  (*)
    echo "Don't understand [${SERVICE}]"
    exit 1
    ;;
esac
