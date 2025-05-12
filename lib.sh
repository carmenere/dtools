function dt_target() {
  if [ -n "$1" ]; then
    echo "${BOLD}[dtools]${RESET} Targert: ${GREEN}${BOLD}$1${RESET}"
    $1
  fi
}

function dt_exec() {
  echo "${BOLD}[dtools]${RESET} Command: ${BOLD}${GRAY} ${cmd} ${RESET}"
  eval ${cmd}
}

function dt_envs_dump() {
  if [ "${DT_DEBUG}" = "yes" ]; then
     echo "${BOLD}[dtools]${RESET} Dump all envs: ${CYAN}${BOLD} ${@} ${RESET}"
     export
  fi
}

# $1 contains name of function that wraps set of variables, for example "psql_user_admin".
function dt_envs_export() {
  vars=$1
  if [ -z "$vars" ]; then echo "Parameter "vars" was not provided. Nothing to export."; return 0; fi
  set -a; $vars; set +a
}

function dt_escape_single_quotes() {
  echo "$1" | sed -e "s/'/\\\\'/g"
}

function dt_rc_load() {
  description=$1
  dir=$2
  if [ -z "${description}" ]; then return 99; fi
  if [ -z "${dir}" ]; then return 99; fi
  echo "Loading $description ... "
  for file in "$dir"/*.sh; do
    if [ "$(basename "$file")" != "rc.sh"  ]; then
      echo -n "Sourcing '$file' ..."
      . "$file"
      echo " done.";
    fi
  done
}

function dt_rc_paths() {
  if [ -z "${DT_DTOOLS}" ]; then DT_DTOOLS="$(pwd)"; fi
  DT_CORE=${DT_DTOOLS}/core
  DT_COMMANDS=${DT_DTOOLS}/commands
  DT_CTXES=${DT_DTOOLS}/ctxes
  DT_STANDS=${DT_DTOOLS}/stands
  DT_LOCAL=${DT_DTOOLS}/.locals
}

function dt_rc() {
  dt_rc_paths
  . "${DT_CORE}/rc.sh"
  . "${DT_COMMANDS}/rc.sh"
  . "${DT_CTXES}/rc.sh"
  . "${DT_STANDS}/rc.sh"
  . "${DT_LOCAL}/rc.sh"
}

function dt_paths() {
  # Derived paths
  DT_ARTEFACTS="${DT_DTOOLS}/.artefacts"
  DT_LOGS_DIR="${DT_ARTEFACTS}/.logs"
}
