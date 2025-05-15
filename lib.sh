# Example: passing named arguments to functions
#function parse_args() {
#    for v in "$@"
#    do
#       case "$v" in
#           name=*) name=${v#*=};;
#           age=*)  age=${v#*=};;
#           *)    echo "Unexpected parameter $v."; return 99;;
#       esac
#    done
#
#    echo "name= $name age= $age"
#}

function dt_error() {
  # $1: must contain $0 of caller
  # $2: must contain err message
  >&2 echo -e "${BOLD}${RED}[dtools][ERROR]${RESET}<in function ${BOLD}$1${RESET}> $2"
}

function dt_info() {
  # $1: info message
  >&2 echo -e "${BOLD}${GREEN}[dtools][INFO]${RESET} $1"
}

function dt_echo() {
  # $1: command to be echoed
  >&2 echo -e "${BOLD}${DT_ECHO_COLOR}[dtools][ECHO]${RESET} Executing command $1"
}

function dt_debug() {
  # $1: debug message
  >&2 echo -e "${BOLD}${MAGENTA}[dtools][DEBUG]${RESET} $1"
}

function dt_target() {
  # $1: name of target. Each target is a callable.
  if [ -z "$1" ]; then return 0; fi
    dt_info "Running target ${BOLD}${GREEN}$1${RESET} ... "
    $1
}

function dt_exec() {
  if [ -z "$1" ]; then return 0; fi
  if [ "${DT_ECHO}" = "y" ]; then
    dt_echo "${DT_ECHO_COLOR} $1 ${RESET}"
  fi
  if ! eval "$1"; then dt_error $0; return 100; fi
}

function dt_debug_args() {
  if [ "${DT_DEBUG}" = "y" ]; then
    dt_debug "${BOLD}function${RESET}: $1, ${BOLD}args${RESET}: '$2'"
  fi
}

# Example: exit_on_err $0 $err_code
# $0 contains name of caller function
function exit_on_err() {
  # $1: must contain $0 of caller
  # $2: error code
  if [ "$2" != 0 ] ; then
    dt_error $1 $0
    return $2
  fi
}

function dt_check_ctx() {
  dt_debug_args "$0" "$*"
  ctx="$1"
  mode="$2"
  if [ -z "${ctx}" ]; then
    dt_error $0 "Empty ctx"; return 99
  fi
  if declare -f "$ctx" > /dev/null; then
    return 0
  else
    dt_error $0 "ctx='$ctx' is NOT callable"; return 99
  fi
}

function dt_ctx() {
  dt_check_ctx $@; exit_on_err $0 $? || return $?
  $ctx; exit_on_err $0 $? || return $?
}

# Example: ( ctx_cargo; dt_inline_envs )
function dt_inline_envs() {
  dt_debug_args "$0" "$*"
  envs=()
  for env in ${_inline_envs}; do
    if [ -z "$env" ]; then continue; fi
    val=$(dt_escape_single_quotes "$(eval echo "\$$env")")
    if [ -n "${val}" ]; then envs+=("${env}=$'${val}'"); fi
  done
  echo "${envs}"
}

# Example: ( ctx_cargo; dt_export_envs; export )
function dt_export_envs() {
  dt_debug_args "$0" "$*"
  envs=()
  for env in ${_envs}; do
    if [ -z "$env" ]; then continue; fi
    val=$(dt_escape_single_quotes "$(eval echo "\$$env")")
    if [ -n "${val}" ]; then envs+=("export ${env}=$'${val}';"); fi
  done
  echo "${envs}"
}

function dt_escape_single_quotes() {
  echo "$1" | sed -e "s/'/\\\\'/g"
}

function dt_rc_load() {
  dt_debug_args "$0" "$*"
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

function dt_check_cmd() {
  dt_debug_args "$0" "$*"
  cmd="$1"
  mode="$2"
  if [ -z "${cmd}" ]; then
    dt_error $0 "cmd is empty cmd='${cmd}'."; return 99
  fi
}

function dt_exec_or_echo() {
  dt_check_cmd $@
  if [ "$mode" = "echo" ]; then
    echo "${cmd}"
  else
    dt_exec "${cmd}"
  fi
}

function dt_run_targets() {
  if [ -z "$1" ]; then return 0; fi
  targets=("$@")
  for target in $@; do
    dt_target $target
  done
}

function dt_sleep_5() {
  sleep 5
}

function dt_paths() {
  if [ -z "${DT_DTOOLS}" ]; then DT_DTOOLS="$(pwd)"; fi

  # Paths that depend on DT_DTOOLS
  export DT_PROJECT="${DT_DTOOLS}"/..
  export DT_ARTEFACTS="${DT_DTOOLS}/.artefacts"
  export DT_CORE=${DT_DTOOLS}/core
  export DT_LOCALS=${DT_DTOOLS}/locals
  export DT_SCRIPTS=${DT_DTOOLS}/scripts
  export DT_TOOLS=${DT_DTOOLS}/tools

  # Paths that depend on DT_ARTEFACTS
  export DT_LOGS="${DT_ARTEFACTS}/.logs"
}

# Example: dt_deploy ctx_stand_host
function dt_deploy() {
  dt_ctx $@; exit_on_err $0 $? || return $?
  for step in $(for s in ${steps}; do echo "${s}"; done | sort -n -t _ -k 2); do
    for target in $(eval echo "\${${step}[@]}"); do dt_target $target; done
  done
}

function dt_defaults() {
  export DT_PROFILES=("dev")
  export DT_ECHO="y"
  export DT_DEBUG="n"
  export DT_ECHO_COLOR="${YELLOW}"
}

function dt_init() {
  dt_paths
  . "${DT_CORE}/colors.sh"
  dt_defaults
  . "${DT_CORE}/rc.sh"
  . "${DT_TOOLS}/rc.sh"
  . "${DT_SCRIPTS}/rc.sh"
  . "${DT_LOCALS}/rc.sh"
}
