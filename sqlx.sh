function crate_sqlx() {
  CRATE_NAME="sqlx-cli"
  CRATE_VERSION="0.8.5"
}

function cargo_install_sqlx() {
  ( crate_sqlx; dt_target cargo_install_locked )
}

function cargo_uninstall_sqlx() {
  ( crate_sqlx; dt_target cargo_uninstall )
}

function sqlx_pre_run() {
  SCHEMAS="${DT_PROJECT_DIR}/migrations/schemas"
  rm -rf "${TMP_SCHEMAS}"
  [ -d "${TMP_SCHEMAS}" ] || mkdir -p "${TMP_SCHEMAS}"
  dt_cmd 'find "${SCHEMAS}" -type f | while read FILE; do echo cp ${FILE} "${TMP_SCHEMAS}"/; cp "${FILE}" "${TMP_SCHEMAS}"/; done'
}

function sqlx_run() {
  TMP_SCHEMAS="${DT_ARTEFACTS}/schemas"
  dt_target sqlx_pre_run
  sqlx migrate run --source "${TMP_SCHEMAS}"
}

function sqlx_prepare() {
  (
    cd "${DT_PROJECT_DIR}"
    dt_cmd "cargo sqlx prepare" #--workspace
  )
}

# call pg_socket and psql_user_migrator, then sqlx_database_url
function sqlx_database_url() {
  DATABASE_URL="postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
}

DT_EXPORTS+=(sqlx_database_url)