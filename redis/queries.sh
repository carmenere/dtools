function redis_create_user() {
  dt_debug_args "$0" "$*"
  query=$(
    dt_ctx $@; exit_on_err $0 $? || return $?
    dt_escape_single_quotes "ACL SETUSER ${REDIS_USER} \>${REDIS_PASSWORD} on allkeys allcommands"
  ); exit_on_err $0 $? || return $?
  echo "${query}"
}

function redis_drop_user() {
  dt_debug_args "$0" "$*"
  query=$(
    dt_ctx $@; exit_on_err $0 $? || return $?
    dt_escape_single_quotes "ACL DELUSER ${REDIS_USER}"
  ); exit_on_err $0 $? || return $?
  echo "${query}"
}

function redis_check_user() {
  dt_debug_args "$0" "$*"
  query=$(
    dt_ctx $@; exit_on_err $0 $? || return $?
    dt_escape_single_quotes "ACL DRYRUN ${REDIS_USER} PING"
  ); exit_on_err $0 $? || return $?
  echo "${query}"
}

function redis_config_rewrite() {
  echo "CONFIG REWRITE"
}

function redis_flushall() {
  echo "FLUSHALL"
}

function redis_set_requirepass() {
  echo "config set requirepass \"\""
}
