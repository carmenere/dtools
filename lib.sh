function dt_target() {
  if [ -n "$1" ]; then
    echo "${BOLD}[dtools]${RESET} Targert: ${GREEN}${BOLD}$1${RESET}"
    $1
  fi
}

function dt_exec() {
  echo dt_exec="$1"
  if [ -n "$1" ]; then
    echo "${BOLD}[dtools]${RESET} Command: ${BOLD}${GRAY} $1 ${RESET}"
    eval $1
  fi
}

#function dt_envs_dump() {
#  if [ "${DT_DEBUG}" = "yes" ]; then
#     echo "${BOLD}[dtools]${RESET} Dump all envs: ${CYAN}${BOLD} ${@} ${RESET}"
#     export
#  fi
#}
#
## $1 contains name of function that wraps set of variables, for example "psql_user_admin".
#function dt_envs_export() {
#  vars=$1
#  if [ -z "$vars" ]; then echo "Parameter "vars" was not provided. Nothing to export."; return 0; fi
#  set -a; $vars; set +a
#}

# ns = namespace for commands, for example cargo.
# ctx = context, it can be fully qualified (ctx_cargo, ctx_cargo_foo, ctx_cargo_build_foo) or short (default, foo)
# The fully qualified has format "ctx_$ns_$cmd_$ctx" or "ctx_$ns_$ctx"
# Example: ( cargo_lookup_ctx ctx_cargo_foo )
# Example: ( cargo_lookup_ctx foo )
#function dt_lookup_ctx() {
#  ctx=$1
#  ns=$2
#  cmd=$3
#
#  # check exact match with $ctx
#  if dt_check_ctx "$ctx"; then
#    echo "$ctx"
#    return 0
#  fi
#
#  # then consider $ctx is a last part of fully qualified ctx
#  dt_check_ns "$ns" || return 99
#  if [ -z "$cmd" ]; then
#    if dt_check_ctx "ctx_$ns_$ctx"; then
#      echo "ctx_$ns_$ctx"
#      return 0
#    else
#      return 91
#    fi
#  else
#    if dt_check_ctx "ctx_$ns_$cmd_$ctx"; then
#      echo "ctx_$ns_$cmd_$ctx"
#      return 0
#    else
#      return 99
#    fi
#  fi
#}

#function dt_check_ns() {
#  if [ -z "$1" ]; then return 90; fi
#}

function dt_check_ctx() {
  ctx=$1
  if [ -z "$ctx" ]; then return 90; fi
  if declare -f $ctx > /dev/null; then
      return 0
  else
      return 99
  fi
}

# Example: ( ctx_cargo; dt_inline_envs )
function dt_inline_envs() {
#  ctx=$1
#  dt_check_ctx "$ctx" || return $?
#  _inline_envs=()
  envs=()
#  $ctx || return $?
  for env in ${_inline_envs}; do
    if [ -z "$env" ]; then continue; fi
    val=$(dt_escape_single_quotes "$(eval echo "\$$env")")
    if [ -n "${val}" ]; then; envs+=("${env}=$'${val}'"); fi
  done
  echo "${envs}"
}

# Example: ( ctx_cargo; dt_export_envs; export )
function dt_export_envs() {
#  ctx=$1
#  dt_check_ctx "$ctx" || return $?
#  _envs=()
  envs=()
#  $ctx || return $?
  for env in ${_envs}; do
    if [ -z "$env" ]; then continue; fi
    val=$(dt_escape_single_quotes "$(eval echo "\$$env")")
    if [ -n "${val}" ]; then; envs+=("export ${env}=$'${val}';"); fi
  done
  echo "${envs}"
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

function dt_paths() {
  if [ -z "${DT_DTOOLS}" ]; then DT_DTOOLS="$(pwd)"; fi

  # Paths that depend on DT_DTOOLS
  DT_ARTEFACTS="${DT_DTOOLS}/.artefacts"
  DT_CORE=${DT_DTOOLS}/core
  DT_LOCALS=${DT_DTOOLS}/locals
  DT_STANDS=${DT_DTOOLS}/stands
  DT_TOOLS=${DT_DTOOLS}/tools

  # Paths that depend on DT_ARTEFACTS
  DT_LOGS="${DT_ARTEFACTS}/.logs"
}

function dt_rc() {
  dt_paths
  . "${DT_CORE}/rc.sh"
  . "${DT_LOCALS}/rc.sh"
  . "${DT_STANDS}/rc.sh"
  . "${DT_TOOLS}/rc.sh"
}
