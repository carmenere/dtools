function app_envs() {
  APP=
  BINARY=
  OPTS=
  PKILL_PATTERN="${BINARY}"
}

function app_log_file() {
  if [ -n "${DT_LOGS}" ]; then
    LOG_FILE="${DT_LOGS}/${APP}.logs"
  else
    LOG_FILE="/tmp/${APP}.logs"
  fi
}

function app_start() {

  if [ -z "${PKILL_PATTERN}" ]; then echo "Parameter PKILL_PATTERN was not provided. Skip." return 0; fi
  if [ -z "${SIGNAL}" ]; then SIGNAL='KILL'; fi

  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  if [ -n "${LOG_FILE}" ] && [ ! -d "$(dirname ${LOG_FILE})" ]; then mkdir -p $(dirname "${LOG_FILE}"); fi

  echo "Starting ${APP}, binary ${BINARY} ..."
  export > ${LOG_FILE}
  ${BINARY} ${OPTS} 2>&1 | tee -a ${LOG_FILE}
}

function app_kill() {
  SIGNAL=$1
  if [ -z "${SIGNAL}" ]; then SIGNAL='KILL'; fi
  echo "Sending signal ${SIGNAL} to ${APP} ..."
  ps -A -o pid,args | grep -v grep | grep "${PKILL_PATTERN}" | awk '{print $1}' | xargs -I {} kill -s ${SIGNAL} {} || true
  echo "done."
}