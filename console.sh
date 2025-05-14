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

function console_start() {
  (
    dt_check_ctx $@; exit_on_err $0 $? || return $?
    $ctx; exit_on_err $0 $? || return $?
    echo "__inline_envs=${_inline_envs}"
    cmd=("$(dt_inline_envs)")

    if [ -z "${PKILL_PATTERN}" ]; then echo "Parameter PKILL_PATTERN was not provided. Skip." return 0; fi
    if [ -z "${SIGNAL}" ]; then SIGNAL='KILL'; fi

    if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
    if [ -n "${LOG_FILE}" ] && [ ! -d "$(dirname ${LOG_FILE})" ]; then mkdir -p $(dirname "${LOG_FILE}"); fi

    echo "Starting ${APP}, binary ${BINARY} ..."
    export > ${LOG_FILE}
    cmd+=("${BINARY}")
    cmd+=("${OPTS}")
    cmd+=('2>&1')
    cmd+=("| tee -a ${LOG_FILE}")
    dt_exec_or_echo "${cmd}"
  )
}

function console_stop() {
  dt_check_ctx $@; exit_on_err $0 $? || return $?
  $ctx; exit_on_err $0 $? || return $?
  if [ -z "${PKILL_PATTERN}" ]; then echo "Parameter PKILL_PATTERN was not provided. Skip." return 99; fi
  echo "Sending signal 'KILL' to ${APP} ..."
  ps -A -o pid,args | grep -v grep | grep "${PKILL_PATTERN}" | awk '{print $1}' | xargs -I {} kill -s 'KILL' {} || true
  echo "done."
}

function console_send_signal() {
  SIGNAL=$2
  if [ -z "${SIGNAL}" ]; then SIGNAL='KILL'; fi
  echo "Sending signal ${SIGNAL} to ${APP} ..."
  ps -A -o pid,args | grep -v grep | grep "${PKILL_PATTERN}" | awk '{print $1}' | xargs -I {} kill -s ${SIGNAL} {} || true
  echo "done."
}
