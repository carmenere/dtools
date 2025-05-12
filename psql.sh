

function psql_history() {
  if [ -z "${HIST_PROFILE}" ]; then return 0; fi

  PSQL_HISTORY="${HIST_DIR}/psql_${HIST_PROFILE}"
}

function psql_db_postgres() {
  PGDATABASE="postgres"
}

function psql_user_admin() {
  PGPASSWORD="postgres"
  if [ "$(os_name)" = "macos" ]; then
    PGUSER="${USER}"
  else
    PGUSER=postgres
  fi
  psql_db_postgres
}

function psql_user_default() {
  psql_user_admin
}

function psql_db_default() {
  psql_db_postgres
}

# If $1 is empty, by it will use psql_user_admin and psql_db_postgres.
function psql_conn() {
  user=$1
  db=$2
  (
    if [ -z "$user" ]; then user=psql_user_default; fi
    if [ -z "$db" ]; then db=psql_db_default; fi
    dt_envs_export psql_user_$user
    dt_envs_export psql_db_$db
    psql
  )
}

function psql_local_admin() {
  (
    psql_user_admin || return $?
    unset PGHOST
    sudo -u ${PGUSER} psql -d ${PGDATABASE}
  )
}

# $1: username
# In postgres the $$ ... $$ means dollar-quoted string.
# So, we must escape each $ to avoid bash substitution: \$\$ ... \$\$.
function psql_create_user() {
  (
    psql_user_$1 || return $?
    QUERY=$(dt_escape_single_quotes "
      SELECT \$\$CREATE USER ${PGUSER} WITH ENCRYPTED PASSWORD '${PGPASSWORD}'\$\$
      WHERE NOT EXISTS (SELECT true FROM pg_roles WHERE rolname = '${PGUSER}')
    ")
    dt_cmd "echo $'${QUERY}' '\gexec' | psql_conn admin postgres" | tr -s ' '
  )
}

# $1: username
function psql_drop_user() {
  (
    psql_user_$1 || return $?
    QUERY="DROP USER IF EXISTS ${PGUSER}"
    dt_cmd "echo $'${QUERY}' '\gexec' | psql_conn admin postgres" | tr -s ' '
  )
}

# $1: username
function psql_create_db() {
  (
    psql_db_$1 || return $?
    QUERY=$(dt_escape_single_quotes "
      SELECT 'CREATE DATABASE ${PGDATABASE}'
      WHERE NOT EXISTS (SELECT true FROM pg_database WHERE datname = '${PGDATABASE}')
    ")
    dt_cmd "echo $'${QUERY}' '\gexec' | psql_conn admin postgres" | tr -s ' '
  )
}

# $1: username
#
function psql_drop_db() {
  (
    psql_db_$1 || return $?
    QUERY=$(dt_escape_single_quotes "
      SELECT 'DROP DATABASE IF EXISTS ${PGDATABASE}'
      WHERE EXISTS (SELECT true FROM pg_database WHERE datname = '${PGDATABASE}')
    ")
    dt_cmd "echo $'${QUERY}' '\gexec' | psql_conn admin postgres" | tr -s ' '
  )
}

function psql_alter_role_password() {
  (
    psql_user_$1 || return $?
    QUERY="ALTER ROLE \"${PGUSER}\" WITH PASSWORD \'${PGPASSWORD}\'"
    dt_cmd "echo $'${QUERY}' '\gexec' | psql_conn admin postgres" | tr -s ' '
  )
}

function psql_alter_admin_password() {
  psql_alter_role_password admin postgres
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



function psql_envs() {
  psql_user_migrator
  psql_db_tetrix
  psql_history
}

DT_EXPORTS+=(psql_envs)