# click sh shortcut for clickhouse-client
function ctx_redis_conn() {
  _export_envs=(REDIS_HOST REDIS_PORT REDIS_DB REDIS_USER REDIS_PASSWORD)
  _inline_envs=()
}

function ctx_redis_conn_admin() {
  ctx_service_redis
  ctx_redis_conn
  redis_db_0
  redis_user_admin
}

function redis_conn_admin() {
  redis_conn ctx_redis_conn_admin
}

function redis_conn() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=("redis-cli -e -u")
    cmd+=("redis://${REDIS_USER}:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}")
    dt_exec_or_echo "${cmd}" $mode
  )
}

# Some commands use one context (cctx) for parameters for connection and another context (tctx) for parameters for template.
# Example: PGUSER=foo click -c "CREATE USER ${PGUSER}", here
#  - first user (PGUSER=foo) is used for connection;
#  - second user ("... ${PGUSER}") is used to generate SQL query;
function redis_cmd() {
  dt_conn_and_tmpl_parse_args $@
  query="$($tmpl $tctx)"
  conn="$(redis_conn $cctx echo)"
  cmd="${conn} ${query}"
  dt_exec_or_echo "$cmd" $mode
}