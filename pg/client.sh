function ctx_psql_conn_admin() {
  ctx_pg
  pg_db_postgres
  pg_user_admin
  _export_envs=(PGHOST PGPORT PGUSER PGDATABASE PGPASSWORD)
  _inline_envs=(${_export_envs[@]})
}

function psql_conn_local_admin() {
  cmd=$(
    ctx_psql_conn_admin
    unset PGHOST
    sudo -u ${PGUSER} psql -d ${PGDATABASE}
  )
  dt_exec_or_echo "$cmd" $mode
}

# "psql_conn_admin" can be run in any context, but it will always rewrite PGUSER and PGPASSWORD to pg_user_admin's values
function psql_conn_admin() {
  psql_conn ctx_psql_conn_admin
}

function psql_conn() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=("${PG_DIR}/psql")
    dt_exec_or_echo "${cmd}" $mode
  )
}

# Some commands use one context (cctx) for parameters for connection and another context (tctx) for parameters for template.
# Example: PGUSER=foo psql -c "CREATE USER ${PGUSER}", here
#  - first user (PGUSER=foo) is used for connection;
#  - second user ("... ${PGUSER}") is used to generate SQL query;
function psql_gexec() {
  dt_conn_and_tmpl_parse_args $@
  query="$($tmpl $tctx)"
  conn="$(psql_conn $cctx echo)"
  cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec_or_echo "$cmd" $mode
}

function psql_cmd() {
  dt_conn_and_tmpl_parse_args $@
  query="$($tmpl $tctx)"
  conn="$(psql_conn $cctx echo)"
  cmd="${conn} -c $'${query}'"
  dt_exec_or_echo "$cmd" $mode
}

#function psql_dump_db() {
#  checks "$@" || return $?
#  local DB=$(. "${DTOOLS}/pg/accounts/$1.sh" && echo "${PGDATABASE}")
#  PG_DUMP="${DT_LOGS}/db-${DB}.dump"
#  [ -d $(dirname ${PG_DUMP}) ] || mkdir -p $(dirname ${PG_DUMP})
#  (
#    . "${DTOOLS}/pg/accounts/admin.sh"
#    pg_dump --format custom --no-owner --no-privileges --file=${PG_DUMP}
#    echo PG_DUMP=${PG_DUMP}
#  )
#}
#
#function psql_restore_db() {
#  checks "$@" || return $?
#  local DB=$(. "${DTOOLS}/pg/accounts/$1.sh" && echo "${PGDATABASE}")
#  PG_DUMP="${DT_LOGS}/db-${PGDATABASE}.dump"
#  (
#    . "${DTOOLS}/pg/accounts/admin.sh"
#    pg_restore --no-owner -d ${DB} --single-transaction "${PG_DUMP}"
#    echo "Ok"
#  )
#}
