function ctx_crate_sqlx() {
  CRATE_NAME="sqlx-cli"
  CRATE_VERSION="0.8.5"
  FORCE=
  FROZEN=
  IGNORE_RUST_VERSION=
  LOCKED=y
  OFFLINE=
}

function cargo_install_sqlx() {
  ( cargo_install ctx_crate_sqlx )
}

function cargo_uninstall_sqlx() {
  ( cargo_uninstall ctx_crate_sqlx )
}

function ctx_sqlx() {
  SCHEMAS="${DT_PROJECT}/migrations/schemas"
  TMP_SCHEMAS="${DT_ARTEFACTS}/schemas"
  DATABASE_URL="postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
  _envs=(DATABASE_URL)
  _inline_envs=(${_envs[@]})
}

function sqlx_pre_run() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    rm -rf "${TMP_SCHEMAS}"
    [ -d "${TMP_SCHEMAS}" ] || mkdir -p "${TMP_SCHEMAS}"
    dt_exec_or_echo "find \"${SCHEMAS}\" -type f | while read FILE; do echo cp \${BOLD}\${FILE}\${RESET} \"\${TMP_SCHEMAS}\"/; cp \"\${FILE}\" \"${TMP_SCHEMAS}\"/; done"
  )
}

function sqlx_run() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    if [ -z "${SCHEMAS}" ]; then >&2 dt_error $0 "path to schemas is empty: SCHEMAS='${SCHEMAS}'."; return 99; fi
    if [ -z "${TMP_SCHEMAS}" ]; then >&2 dt_error $0 "path to temporary schemas is empty: TMP_SCHEMAS='${TMP_SCHEMAS}'."; return 99; fi
    sqlx_pre_run $ctx $mode
    cmd=("$(dt_inline_envs)")
    cmd+=(sqlx migrate run)
    cmd+=(--source "'${TMP_SCHEMAS}'")
    dt_exec_or_echo "${cmd}" $mode
  )
}

function sqlx_prepare() {
  (
    cd "${DT_PROJECT_DIR}"
    dt_exec_or_echo "cargo sqlx prepare" #--workspace
  )
}
