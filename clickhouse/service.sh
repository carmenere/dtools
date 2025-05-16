function ch_service() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ "$(os_name)" = "macos" ]; then
      echo "clickhouse@${CH_MAJOR}.${CH_MINOR}"
    else
      echo "clickhouse-server"
    fi
  )
}

function clickhouse_conf() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ "$(os_name)" = "macos" ]; then
      echo "$(brew_prefix)/etc/clickhouse-server/config.xml"
    else
      echo "/etc/clickhouse-server/config.xml"
    fi
  )
}

function ch_install() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      ${SUDO} apt-get install -y apt-transport-https ca-certificates curl gnupg
      curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | sudo gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main" | sudo tee /etc/apt/sources.list.d/clickhouse.list
      sudo apt-get update
      sudo apt-get install -y clickhouse-server clickhouse-client

    elif [ "$(os_kernel)" = "Darwin" ]; then
      brew install "${CH_SERVICE}"

    else
      echo "Unsupported OS: '$(os_kernel)'"; exit;
    fi
  )
}

function ch_prepare_admin_xml() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ "$(os_name)" = "macos" ]; then
      SUDO="sudo -E"
    else
      SUDO="sudo"
    fi
    dt_exec_or_echo "${SUDO} cp -f \"${CH_USER_XML_DT}\" \"${CH_USER_XML}\""
  )
}

function ch_user_xml_dir() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ "$(os_name)" = "macos" ]; then
      echo "$(brew_prefix)/etc/clickhouse-server/users.d"
    else
      echo "/etc/clickhouse-server/users.d"
    fi
  )
}

function ctx_service_ch() {
  CLICKHOUSE_DB="default"
  CLICKHOUSE_HOST="localhost"
  CLICKHOUSE_PASSWORD="1234567890"
  CLICKHOUSE_USER="dt_admin"
  # for clickhouse-client
  CLICKHOUSE_PORT=9000
  # for applications
  CLICKHOUSE_HTTP_PORT=8123
  CH_MAJOR=23
  CH_MINOR=5
  CH_PATCH=46
  CH_VERSION="${CH_MAJOR}.${CH_MINOR}.${CH_PATCH}"

  CH_USER_XML_DT="${DT_CORE}/clickhouse/admin.xml"
  CH_USER_XML="$(ch_user_xml_dir _)/admin.xml"; exit_on_err $0 $? || return $?
  CH_SERVICE=$(ch_service _); exit_on_err $0 $? || return $?
  CH_CONFIG_XML=$(clickhouse_conf _); exit_on_err $0 $? || return $?
  
  _export_envs=(
    CLICKHOUSE_HOST
    CLICKHOUSE_PORT
    CLICKHOUSE_USER
    CLICKHOUSE_PASSWORD
    CLICKHOUSE_DB
    CLICKHOUSE_HTTP_PORT
    CH_USER_XML
    CH_MAJOR
    CH_MINOR
    CH_PATCH
    CH_VERSION
    CH_SERVICE
    CH_CONFIG_XML
    CH_USER_XML_DT
  )
}

function ch_user_admin() {
  CLICKHOUSE_PASSWORD="1234567890"
  CLICKHOUSE_USER="dt_admin"
}

function ch_db_postgres() {
  CLICKHOUSE_DB="default"
}

function service_ch_stop() {
  (
    ctx_service_ch
    SERVICE=${CH_SERVICE}
    service_stop $ctx
  )
}

function service_ch_start() {
  (
    ctx_service_ch
    SERVICE=${CH_SERVICE}
    service_start $ctx
  )
}

function lsof_ch() {
  (
    ctx_service_ch
    HOST=${CLICKHOUSE_HOST}
    PORT=${CLICKHOUSE_PORT}
    lsof_tcp
    PORT=${CLICKHOUSE_HTTP_PORT};
    lsof_tcp
  )
}