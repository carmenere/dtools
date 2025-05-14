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

function dt_debug() {
  # $1 must contain info message
  >&2 echo "${BOLD}[dtools]${MAGENTA}[DEBUG]${RESET} $1"
}

function dt_info() {
  # $1 must contain info message
  >&2 echo "${BOLD}[dtools]${GREEN}[INFO]${RESET} $1"
}

function dt_error() {
  # $1: must contain $0 of caller
  # $2: must contain err message
  >&2 echo "${BOLD}[dtools]${RED}[ERROR]${RESET}<in function ${BOLD}$1${RESET}> $2"
}

function dt_target() {
  # $1 must contain $0 of caller
  if [ -z "$1" ]; then return 0; fi
    >&2 echo "${BOLD}[dtools][targert] ${GREEN}$1${RESET}"
  $1
}

function dt_exec() {
  if [ -z "$1" ]; then return 0; fi
  if [ "$DT_EXEC_ECHO" = "y" ]; then
    >&2 echo "${BOLD}[dtools][command]${RESET} ${DT_EXEC_COLOR} $1 ${RESET}."
  fi
  if ! eval "$1"; then >&2 echo "$(dt_error $0)"; return 99; fi
}

function dt_debug_args() {
  if [ "$DT_EXEC_DEBUG" = "y" ]; then
    dt_debug "${BOLD}function${RESET}: $1, ${BOLD}args${RESET}: '$2'."
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

# "ctx" = context. It can be fully qualified (ctx_cargo, ctx_cargo_foo, ctx_cargo_build_foo) or short (default, foo)
# The fully qualified has format "$prefix_$ctx"
# Example: ( cargo_lookup_ctx ctx_cargo_foo )
# Example: ( cargo_lookup_ctx foo )
function dt_lookup_ctx() {
  if [ -z "$1" ]; then return 0; fi
  local orig_ctx=$1
  shift
  local prefixes=("$@")

  if dt_check_ctx "${orig_ctx}"; then
    echo "${orig_ctx}"
    return 0
  fi

  for p in ${prefixes}; do
    ctx="${p}_${orig_ctx}"
    if dt_check_ctx "${ctx}"; then
      echo "${ctx}"
      return 0
    fi
  done

  dt_error $0 "Cannot find ctx '${orig_ctx}' in prefixes '${prefixes}'."
  return 99
}

function dt_check_ctx() {
  dt_debug_args "$0" "$*"
  ctx="$1"
  if [ -z "$ctx" ]; then return 90; fi
  if declare -f "$ctx" > /dev/null; then
      return 0
  else
      return 99
  fi
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
  cmd="$1"; mode="$2"
  if [ -z "${cmd}" ]; then
    dt_error $0 "cmd is empty cmd='${cmd}'."; return 99
  fi
}

function dt_check_ctx() {
  dt_debug_args "$0" "$*"
  ctx="$1"; mode="$2"
  if [ -z "${ctx}" ]; then
    dt_error $0 "ctx is empty ctx='${ctx}'."; return 99
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

function dt_paths() {
  if [ -z "${DT_DTOOLS}" ]; then DT_DTOOLS="$(pwd)"; fi

  # Paths that depend on DT_DTOOLS
  export DT_PROJECT="${DT_DTOOLS}"/..
  export DT_ARTEFACTS="${DT_DTOOLS}/.artefacts"
  export DT_CORE=${DT_DTOOLS}/core
  export DT_LOCALS=${DT_DTOOLS}/locals
  export DT_STANDS=${DT_DTOOLS}/stands
  export DT_TOOLS=${DT_DTOOLS}/tools

  # Paths that depend on DT_ARTEFACTS
  export DT_LOGS="${DT_ARTEFACTS}/.logs"
}

function dt_defaults() {
  dt_paths
  export DT_PROFILES=("dev")
  export DT_EXEC_ECHO="y"
  export DT_EXEC_COLOR="${YELLOW}"
  export DT_EXEC_DEBUG="y"
}

function dt_init() {
  dt_defaults
  . "${DT_CORE}/rc.sh"
  . "${DT_LOCALS}/rc.sh"
  . "${DT_STANDS}/rc.sh"
  . "${DT_TOOLS}/rc.sh"
}
