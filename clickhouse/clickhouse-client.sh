function ctx_click_conn() {
  _export_envs=(CLICKHOUSE_HOST CLICKHOUSE_PORT CLICKHOUSE_DB CLICKHOUSE_USER CLICKHOUSE_PASSWORD)
  _inline_envs=(${_export_envs[@]})
}

function ctx_click_conn_admin() {
  ctx_service_ch
  ctx_click_conn
  ch_db_tetrix
  ch_user_admin
}

function click_conn_admin() {
  click_conn ctx_click_conn_admin
}

function click_conn() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=("clickhouse-client")
    dt_exec_or_echo "${cmd}" $mode
  )
}

# Some commands use one context (cctx) for parameters for connection and another context (tctx) for parameters for template.
# Example: PGUSER=foo click -c "CREATE USER ${PGUSER}", here
#  - first user (PGUSER=foo) is used for connection;
#  - second user ("... ${PGUSER}") is used to generate SQL query;
function click_cmd() {
  dt_conn_and_tmpl_parse_args $@
  query="$($tmpl $tctx)"
  conn="$(click_conn $cctx echo)"
  cmd="${conn} --multiquery $'${query}'"
  dt_exec_or_echo "$cmd" $mode
}
