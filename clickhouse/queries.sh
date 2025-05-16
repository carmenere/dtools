function ch_sql_create_user() {
  dt_debug_args "$0" "$*"
  query=$(
    dt_ctx $@; exit_on_err $0 $? || return $?
    dt_escape_single_quotes "CREATE USER IF NOT EXISTS ${CLICKHOUSE_USER} IDENTIFIED WITH sha256_password BY '${CLICKHOUSE_PASSWORD}';"
  ); exit_on_err $0 $? || return $?
  echo "${query}"
}

function ch_sql_drop_user() {
  dt_debug_args "$0" "$*"
  query=$(
    dt_ctx $@; exit_on_err $0 $? || return $?
    dt_escape_single_quotes "DROP USER IF EXISTS ${CLICKHOUSE_USER};"
  ); exit_on_err $0 $? || return $?
  echo "${query}"
}

function ch_sql_create_db() {
  dt_debug_args "$0" "$*"
  query=$(
    dt_ctx $@; exit_on_err $0 $? || return $?
    dt_escape_single_quotes "CREATE DATABASE IF NOT EXISTS ${CLICKHOUSE_DB};"
  ); exit_on_err $0 $? || return $?
  echo "${query}"
}

function ch_sql_drop_db() {
  dt_debug_args "$0" "$*"
  query=$(
    dt_ctx $@; exit_on_err $0 $? || return $?
    dt_escape_single_quotes "DROP DATABASE IF EXISTS ${CLICKHOUSE_DB};"
  ); exit_on_err $0 $? || return $?
  echo "${query}"
}

function ch_sql_grant_user_app() {
  dt_debug_args "$0" "$*"
  query=$(
    dt_ctx $@; exit_on_err $0 $? || return $?
    dt_escape_single_quotes "GRANT ALL ON ${CLICKHOUSE_DB}.* TO ${CLICKHOUSE_USER}; GRANT ALL ON default.* TO ${CLICKHOUSE_USER};"
  ); exit_on_err $0 $? || return $?
  echo "${query}"
}