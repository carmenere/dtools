psql_prefs=(ctx_psql_conn pg_db)

function ctx_psql_conn_admin() {
  ctx_pg_tetrix
  pg_db_postgres
  pg_user_admin
}

# for example, pattern may be *=
#${VAR#pattern}     # delete shortest match of pattern from the beginning
#${VAR##pattern}    # delete longest match of pattern from the beginning
#${VAR%pattern}     # delete shortest match of pattern from the end
#${VAR%%pattern}    # delete longest match of pattern from the end

function psql_exec_query_parse_args() {
#  echo "psql_exec_query_parse_args, ARGS: $@"
  for v in "$@"; do
    case "$v" in
      q=*) qctx=${v#*=};; # query ctx
      c=*) cctx=${v#*=};; # conn ctx
      t=*) qtmpl=${v#*=};; # query template
      m=*) mode=${v#*=};;
      *) echo "${RED}[dtools][ERROR][function $0] unexpected parameter $v.${RESET}"; return 99;;
    esac
  done
  if [ -z "${qctx}" ]; then
    echo "${RED}[dtools][ERROR][function $0] query ctx is empty: qctx='${qctx}'.${RESET}"; return 99
  fi
  if [ -z "${cctx}" ]; then
    echo "${RED}[dtools][ERROR][function $0] connection ctx is empty: cctx='${cctx}'.${RESET}"; return 99
  fi
  if [ -z "${qtmpl}" ]; then
    echo "${RED}[dtools][ERROR][function $0] query template is empty: qtmpl='${qtmpl}'.${RESET}"; return 99
  fi
}

function psql_exec() {
  psql_exec_parse_args "$@" || return 99
  if [ "$mode" = "echo" ]; then
    echo "${cmd}"
  else
    dt_exec "${cmd}"
  fi
}

function psql_conn_parse_args() {
  for v in "$@"; do
    case "$v" in
      ctx=*) ctx=${v#*=};; # conn ctx
      m=*) mode=${v#*=};;
      *) echo "${RED}[dtools][ERROR][function $0] unexpected parameter $v.${RESET}"; return 99;;
    esac
  done
  if [ -z "${ctx}" ]; then
    echo "${RED}[dtools][ERROR][function $0] ctx is empty ctx='ctx'.${RESET}"; return 99
  fi
}

function psql_conn() {
  (
    # It possible to pass ctx to psql_conn explicitly or run psql_conn without args inside some ctx
    if [ -n "$1" ]; then
      psql_conn_parse_args "$@" || return 99
    fi
    ctx=$(dt_lookup_ctx "$ctx" "${psql_prefs[@]}" || return $?) || return 99
    # If ctx was passed - call it, or skip. If ctx doesn't exist - return
    $ctx
    cmd=("$(dt_inline_envs)")
    cmd+=(psql)
    psql_exec cmd="${cmd}" m=$mode
  )
}

function psql_exec_query() {
  echo "psql_exec_query, ARGS: $@"
  psql_exec_query_parse_args "$@" || return 99
  echo "psql_exec_query, PARSED, qctx=$qctx"
  query="$($qtmpl $qctx || return 99)" || return $?
  echo ">>>> psql_exec_query, query=${query}"
  conn="$(psql_conn ctx=$cctx m=echo)"
  echo ">>>> psql_exec_query, conn=${conn}"
  cmd="echo $'${query}' '\gexec' | ${conn}"
  psql_exec cmd="$cmd" m=$mode
}

function psql_exec_parse_args() {
  for v in "$@"; do
    case "$v" in
      cmd=*) cmd=${v#*=};;
      m=*) mode=${v#*=};;
      *) echo "${RED}[dtools][ERROR][function $0] unexpected parameter $v.${RESET}"; return 99;;
    esac
  done
  if [ -z "${cmd}" ]; then
    echo "${RED}[dtools][ERROR][function $0] cmd is empty cmd='$cmd'.${RESET}"; return 99
  fi
}

function psql_conn_local_admin() {
  cmd=$(
    ctx_psql_conn_admin || return $?
    unset PGHOST
    sudo -u ${PGUSER} psql -d ${PGDATABASE}
  )
  psql_exec cmd="$cmd" m=$mode
}

# "psql_conn_admin" can be run in any context, but it will always rewrite PGUSER and PGPASSWORD to pg_user_admin's values
function psql_conn_admin() {
  psql_conn ctx=admin
}

function psql_cmd() {
  psql_exec_query_parse_args "$@" || return 99
  if ! cctx=$(dt_lookup_ctx "${cctx}" "${psql_prefs[@]}" || return 99); then return $?; fi
  if ! qctx=$(dt_lookup_ctx "${qctx}" "${psql_prefs[@]}" || return 99); then return $?; fi
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

