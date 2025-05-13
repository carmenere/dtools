# Example: passing named arguments to functions
#function parse_args() {
#    for v in "$@"
#    do
#       case "$v" in
#           name=*) name=${v/*=/};;
#           age=*)  age=${v/*=/};;
#           *)    echo "Unexpected parameter $v."; return 99;;
#       esac
#    done
#
#    echo "name= $name age= $age"
#}

function dt_target() {
  if [ -n "$1" ]; then
    echo "${BOLD}[dtools]${RESET} Targert: ${GREEN}${BOLD}$1${RESET}"
    $1
  fi
}

function dt_exec() {
  if [ -n "$1" ]; then
    echo "${BOLD}[dtools]${RESET} Command: ${BOLD}${GRAY} $1 ${RESET}"
    eval $1
  fi
}

# ctx = context. It can be fully qualified (ctx_cargo, ctx_cargo_foo, ctx_cargo_build_foo) or short (default, foo)
# The fully qualified has format "$prefix_$ctx"
# Example: ( cargo_lookup_ctx ctx_cargo_foo )
# Example: ( cargo_lookup_ctx foo )
function dt_lookup_ctx() {
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

  echo "${RED}[dtools][ERROR][function $0] Cannot find ctx '${orig_ctx}' in prefixes '${prefixes}'.${RESET}"
  return 99
}

function dt_check_ctx() {
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
#  ctx=$1
#  dt_check_ctx "$ctx" || return $?
#  _inline_envs=()
  envs=()
#  $ctx || return $?
  for env in ${_inline_envs}; do
    if [ -z "$env" ]; then continue; fi
    val=$(dt_escape_single_quotes "$(eval echo "\$$env")")
    if [ -n "${val}" ]; then envs+=("${env}=$'${val}'"); fi
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
    if [ -n "${val}" ]; then envs+=("export ${env}=$'${val}';"); fi
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
