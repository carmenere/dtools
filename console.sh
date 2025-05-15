function ctx_app_checks() {
  # OPTS is optional parameter, but APP, BINARY, LOG_FILE and PKILL_PATTERN are mandatory.
  if [ -z "${APP}" ]; then echo "Parameter APP is empty. Skip." return 0; fi
  if [ -z "${BINARY}" ]; then echo "Parameter BINARY is empty. Skip." return 0; fi
  if [ -z "${LOG_FILE}" ]; then echo "Parameter LOG_FILE is empty. Skip." return 0; fi
  if [ -z "${PKILL_PATTERN}" ]; then echo "Parameter PKILL_PATTERN is empty. Skip." return 0; fi
}

function app_log_file() {
  if [ -n "${DT_LOGS}" ]; then
    LOG_FILE="${DT_LOGS}/${APP}.logs"
  fi
}

function console_start() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")

    if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
    if [ -n "${LOG_FILE}" ] && [ ! -d "$(dirname ${LOG_FILE})" ]; then mkdir -p $(dirname "${LOG_FILE}"); fi

    echo "Starting ${APP}, binary ${BINARY} ..."
    export > ${LOG_FILE}
    cmd+=("${BINARY}")
    cmd+=("${OPTS}")
    cmd+=("2>&1 | tee -a ${LOG_FILE}")
    dt_exec_or_echo "${cmd}"
  )
}

function console_stop() {
  dt_ctx $@; exit_on_err $0 $? || return $?
  echo "Sending signal 'KILL' to ${APP} ..."
  cmd="ps -A -o pid,args | grep -v grep | grep '${PKILL_PATTERN}' | awk '{print \$1}' | xargs -I {} kill -s 'KILL' {} || true"
  dt_exec_or_echo "${cmd}"
  echo "done."
}
