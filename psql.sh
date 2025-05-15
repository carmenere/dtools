function ctx_psql_connn() {
  _export_envs=(PGHOST PGPORT PGUSER PGDATABASE PGPASSWORD)
  _inline_envs=(${_export_envs[@]})
}

function ctx_psql_conn_admin() {
  ctx_psql_connn
  ctx_pg
  pg_db_postgres
  pg_user_admin
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

# for example, pattern may be *=
#${VAR#pattern}     # delete shortest match of pattern from the beginning
#${VAR##pattern}    # delete longest match of pattern from the beginning
#${VAR%pattern}     # delete shortest match of pattern from the end
#${VAR%%pattern}    # delete longest match of pattern from the end

function psql_cmd_parse_args() {
  dt_debug_args "$0" "$*"
  for v in $@; do
    case "$v" in
      q=*) qctx=${v#*=};; # MANDATORY: query ctx
      c=*) cctx=${v#*=};; # MANDATORY: connection ctx,
      t=*) qtmpl=${v#*=};; # MANDATORY: query template
      m=*) mode=${v#*=};;
      *) >&2 dt_error $0 "unexpected parameter $v."; return 99;;
    esac
  done
  if [ -z "${qctx}" ]; then
    >&2 dt_error $0 "query ctx is empty: qctx='${qctx}'."; return 99
  fi
  if [ -z "${cctx}" ]; then
    >&2 dt_error $0 "connection ctx is empty: cctx='${cctx}'."; return 99
  fi
  if [ -z "${qtmpl}" ]; then
    >&2 dt_error $0 "query template is empty: qtmpl='${qtmpl}'."; return 99
  fi
}

function psql_conn() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=("${PG_DIR}/psql")
    dt_exec_or_echo "${cmd}" $mode
  )
}

function psql_gexec() {
  psql_cmd_parse_args $@
  query="$($qtmpl $qctx)"
  conn="$(psql_conn $cctx echo)"
  cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec_or_echo "$cmd" $mode
}

function psql_cmd() {
  psql_cmd_parse_args $@
  query="$($qtmpl $qctx)"
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
