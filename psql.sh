function ctx_psql_conn_admin() {
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
  psql_exec cmd="$cmd" m=$mode
}

# "psql_conn_admin" can be run in any context, but it will always rewrite PGUSER and PGPASSWORD to pg_user_admin's values
function psql_conn_admin() {
  psql_conn ctx=admin
}

# for example, pattern may be *=
#${VAR#pattern}     # delete shortest match of pattern from the beginning
#${VAR##pattern}    # delete longest match of pattern from the beginning
#${VAR%pattern}     # delete shortest match of pattern from the end
#${VAR%%pattern}    # delete longest match of pattern from the end

function psql_exec_query_parse_args() {
  for v in "$@"; do
    case "$v" in
      q=*) qctx=${v#*=};; # MANDATORY: query ctx
      c=*) cctx=${v#*=};; # MANDATORY: connection ctx,
      t=*) qtmpl=${v#*=};; # MANDATORY: query template
      m=*) mode=${v#*=};;
      *) >&2 echo "$(dt_err $0) unexpected parameter $v."; return 99;;
    esac
  done
  if [ -z "${qctx}" ]; then
    >&2 echo "$(dt_err $0) query ctx is empty: qctx='${qctx}'."; return 99
  fi
  if [ -z "${cctx}" ]; then
    >&2 echo "$(dt_err $0) connection ctx is empty: cctx='${cctx}'."; return 99
  fi
  if [ -z "${qtmpl}" ]; then
    >&2 echo "$(dt_err $0) query template is empty: qtmpl='${qtmpl}'."; return 99
  fi
}

function psql_conn() {
  (
    dt_parse_cmd_args "$@"
    $ctx
    cmd=("$(dt_inline_envs)")
    cmd+=("${PG_DIR}/psql")
    psql_exec cmd="${cmd}" m=$mode
  )
}

function psql_exec_query() {
  psql_exec_query_parse_args "$@"
  query="$($qtmpl $qctx)"
  conn="$(psql_conn ctx=$cctx m=echo)"
  cmd="echo $'${query}' '\gexec' | ${conn}"
  psql_exec cmd="$cmd" m=$mode
}

function psql_cmd() {
  psql_exec_query_parse_args "$@"
  psql_exec_query "q=$qctx" "c=$cctx" "t=$qtmpl" "m=$mode"
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
