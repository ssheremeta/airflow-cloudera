#!/bin/bash

###
function log {
  timestamp=$(date)
  echo "$timestamp: $1"       #stdout
  echo "$timestamp: $1" 1>&2; #stderr
}

###
function substitute_common_tokens {
    log "Replace common substitution parameters in airflow.cfg"

    sed -i "s#{{AIRFLOW_HOME}}#$AIRFLOW_HOME#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CORE__LOG_LEVEL}}#$CORE__LOG_LEVEL#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CORE__DAGS_FOLDER}}#$CORE__DAGS_FOLDER#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CORE__PLUGINS_FOLDER}}#$CORE__PLUGINS_FOLDER#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CORE__EXECUTOR}}#$CORE__EXECUTOR#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CORE__METADATA_CONN_TYPE}}#$CORE__METADATA_CONN_TYPE#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CORE__METADATA_CONN_LOGIN}}#$CORE__METADATA_CONN_LOGIN#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CORE__METADATA_CONN_PASSWORD}}#$CORE__METADATA_CONN_PASSWORD#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CORE__METADATA_CONN_HOST}}#$CORE__METADATA_CONN_HOST#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CORE__METADATA_CONN_PORT}}#$CORE__METADATA_CONN_PORT#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CORE__METADATA_CONN_DB}}#$CORE__METADATA_CONN_DB#g" "$AIRFLOW_CONFIG"

    sed -i "s#{{CELERY__BROKER_URL}}#$CELERY__BROKER_URL#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CELERY__CONCURRENCY}}#$CELERY__CONCURRENCY#g" "$AIRFLOW_CONFIG"

    sed -i "s#{{SCHEDULER__CHILD_PROCESS_LOG_DIR}}#$SCHEDULER__CHILD_PROCESS_LOG_DIR#g" "$AIRFLOW_CONFIG"
}

###
function substitute_webserver_tokens {
    log "Replace webserver substitution parameters in airflow.cfg"

    sed -i "s#{{WEBSERVER__WEB_SERVER_HOST}}#$WEBSERVER__WEB_SERVER_HOST#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{WEBSERVER__WEB_SERVER_PORT}}#$WEBSERVER__WEB_SERVER_PORT#g" "$AIRFLOW_CONFIG"
}

###
function substitute_celery_tokens {
    log "Replace celery substitution parameters in airflow.cfg"

    sed -i "s#{{CELERY__FLOWER_HOST}}#$CELERY__FLOWER_HOST#g" "$AIRFLOW_CONFIG"
    sed -i "s#{{CELERY__FLOWER_PORT}}#$CELERY__FLOWER_PORT#g" "$AIRFLOW_CONFIG"
}

###
function substitute_scheduler_tokens {
    log "Replace scheduler substitution parameters in airflow.cfg"

    sed -i "s#{{SCHEDULER__MAX_THREADS}}#$SCHEDULER__MAX_THREADS#g" "$AIRFLOW_CONFIG"
}


###
function _kill_running_processes {
    ps_pattern="$1"
#    echo $ps_pattern
    ps_number=`ps -fea | grep "$ps_pattern" | grep -v grep | wc -l`
    if [ "$ps_number" != "0" ]
    then
        ps -fea | grep "$ps_pattern" | grep -v grep | awk '{print $2}' | xargs kill -9
    fi
}

###
function _check_processes_running {
    local retval=0
    ps_pattern="$1"
    ps_number=`ps -fea | grep "$ps_pattern" | grep -v grep | wc -l`
    if [ "$ps_number" != "0" ]
    then
        retval=0
    else
        retval=1
    fi
    return "$retval"
}

###
function stop_webserver {
    log "Killing Webserver process"
    _kill_running_processes "airflow webserver"

    log "Killing Gunicorn master process"
    _kill_running_processes "gunicorn: master \[airflow-webserver\]"

    log "Killing Gunicorn worker processes"
    _kill_running_processes "gunicorn: worker \[airflow-webserver\]"

    log "Killing Webserver-multilog process"
    _kill_running_processes "multilog \-p $WEBSERVER__MULTILOG_PORT"
}

###
function check_webserver_running {
    log "Checking Webserver process is running"
    local retval=0

    _check_processes_running "gunicorn: master \[airflow-webserver\]"
    if [ "$?" != "0" ]
    then
        log "Webserver not running!!!"
        retval=1
    fi 

    _check_processes_running "multilog \-p $WEBSERVER__MULTILOG_PORT"
    if [ "$?" != "0" ]
    then
        log "Webserver-multilog not running!!!"
        retval=1
    fi 
    
    return "$retval"
}

