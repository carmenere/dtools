psql_ctx_prefixes=(ctx_psql_conn pg_db)

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

function psql_exec_parse_args() {
  ERR=""
  for v in "$@"; do
    case "$v" in
      cmd=*) cmd=${v#*=};;
      m=*) mode=${v#*=};;
      *) >&2 echo "$(dt_err $0) unexpected parameter $v."; return 99;;
    esac
  done
  if [ -z "${cmd}" ]; then
    >&2 echo "$(dt_err $0) cmd is empty cmd='$cmd'."; return 99
  fi
}

function psql_conn_parse_args() {
  for v in "$@"; do
    case "$v" in
      ctx=*) ctx=${v#*=};; # conn ctx
      m=*) mode=${v#*=};;
      *) >&2 echo "$(dt_err $0) unexpected parameter $v."; return 99;;
    esac
  done
  if [ -z "${ctx}" ]; then
    >&2 echo "$(dt_err $0) ctx is empty ctx='ctx'."; return 99
  fi
}

function psql_exec() {
  psql_exec_parse_args "$@"
  if [ "$mode" = "echo" ]; then
    echo "${cmd}"
  else
    dt_exec "${cmd}"
  fi
}

function psql_conn() {
  (
    psql_conn_parse_args "$@"
    ctx=$(dt_lookup_ctx "$ctx" "${psql_ctx_prefixes[@]}")
    # If ctx was passed - call it, or skip. If ctx doesn't exist - return
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
  cctx=$(dt_lookup_ctx "${cctx}" "${psql_ctx_prefixes[@]}")
  qctx=$(dt_lookup_ctx "${qctx}" "${psql_ctx_prefixes[@]}")
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
