# '\gexec'
# echo "${query}" '\gexec' | ...
function psql_exec() {
  if [ "$2" = "echo" ]; then echo "$1"; else dt_exec "$1"; fi
}

function psql_history() {
  if [ -z "${HIST_PROFILE}" ]; then return 0; fi

  PSQL_HISTORY="${HIST_DIR}/psql_${HIST_PROFILE}"
}

# Example ( pg_user_admin; pg_db_postgres; psql_conn)
function psql_conn() {
  cmd=("$(dt_inline_envs)")
  cmd+=(psql)
  echo "${cmd}"
}

function psql_conn_local_admin() {
  cmd=$(
    pg_user_admin || return $?
    unset PGHOST
    sudo -u ${PGUSER} psql -d ${PGDATABASE}
  )
  psql_exec "${cmd}" "$1"
}

# "psql_conn_admin" can be run in any context, but it will always rewrite PGUSER and PGPASSWORD to pg_user_admin's values
function psql_conn_admin() {
  cmd=$( pg_user_admin; psql_conn )
  psql_exec "${cmd}" "$1"
}

function psql_alter_admin_password() {
  query=$( pg_user_admin; pg_sql_alter_role_password )
  cmd=$(pg_db_postgres; psql_conn_admin echo)
  cmd="echo $'${query}' | ${cmd}"
  psql_exec "${cmd}" "$1"
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
