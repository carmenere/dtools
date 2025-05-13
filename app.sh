function app_envs() {
  APP=
  BINARY=
  OPTS=
  PKILL_PATTERN="${BINARY}"
}

function app_log_file() {
  if [ -n "${DT_LOGS}" ]; then
    LOG_FILE="${DT_LOGS}/${APP}.logs"
  fi
}

function app_start() {
  (
    dt_parse_cmd_args "$@"; exit_on_err $? "$(dt_err $0)" || return $?
    $ctx; exit_on_err $? "$(dt_err $0)" || return $?
    dt_export_envs

    if [ -z "${PKILL_PATTERN}" ]; then echo "Parameter PKILL_PATTERN was not provided. Skip." return 0; fi
    if [ -z "${SIGNAL}" ]; then SIGNAL='KILL'; fi

    if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
    if [ -n "${LOG_FILE}" ] && [ ! -d "$(dirname ${LOG_FILE})" ]; then mkdir -p $(dirname "${LOG_FILE}"); fi

    echo "Starting ${APP}, binary ${BINARY} ..."
    export > ${LOG_FILE}
    dt_exec_or_echo "${BINARY} ${OPTS} 2>&1 | tee -a ${LOG_FILE}"
  )
}

function app_kill() {
  SIGNAL=$1
  if [ -z "${SIGNAL}" ]; then SIGNAL='KILL'; fi
  echo "Sending signal ${SIGNAL} to ${APP} ..."
  ps -A -o pid,args | grep -v grep | grep "${PKILL_PATTERN}" | awk '{print $1}' | xargs -I {} kill -s ${SIGNAL} {} || true
  echo "done."
}