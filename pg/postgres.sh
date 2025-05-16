function pg_dir() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ "$(os_name)" = "macos" ]; then
      echo "$(brew_prefix)/opt/postgresql@${PG_MAJOR}/bin"
    elif [ "$(os_name)" = "alpine" ]; then
      echo "/usr/libexec/postgresql${PG_MAJOR}"
    else
      echo "/usr/lib/postgresql/${PG_MAJOR}/bin"
    fi
  )
}

function pg_new_path() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    NPATH="${PATH}"
    echo "${NPATH}" | grep -E -s "^${PG_DIR}" 1>/dev/null 2>&1
    if [ $? != 0 ] && [ -n "${PG_DIR}" ]; then
      # Cut all duplicates of ${PG_DIR} from NPATH
      NPATH="$(echo "${NPATH}" | sed -E -e ":label; s|(.*):${PG_DIR}(.*)|\1\2|g; t label;")"
      # Prepend ${PG_DIR}
      echo "${PG_DIR}:${NPATH}"
    else
      echo "${NPATH}"
    fi
  )
}

function pg_service() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ "$(os_name)" = "macos" ]; then
      echo "postgresql@${PG_MAJOR}"
    else
      echo "postgresql"
    fi
  )
}



function pg_hba_conf() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ "$(os_name)" = "macos" ]; then
      echo "$(brew_prefix)/var/${PG_SERVICE}/pg_hba.conf"
    else
      echo "/etc/postgresql/${PG_MAJOR}/main/pg_hba.conf"
    fi
  )
}

function pg_conf() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ "$(os_name)" = "macos" ]; then
      echo "$(brew_prefix)/var/${PG_SERVICE}/postgresql.conf"
    else
      echo "/etc/postgresql/${PG_MAJOR}/main/postgresql.conf"
    fi
  )
}

function pg_install() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
        echo "deb http://apt.postgresql.org/pub/repos/apt ${OS_CODENAME}-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
        sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        sudo apt-get update
        sudo apt-get -y install \
            postgresql-${PG_MAJOR} \
            postgresql-server-dev-${PG_MAJOR} \
            libpq-dev
  
    elif [ "$(os_kernel)" = "Darwin" ]; then
      dt_exec "brew install \"${SERVICE}\""
    else
      echo "Unsupported OS: '$(os_kernel)'"; exit;
    fi
  )
}

# sed branching - Example
#echo "apple pie
#apple tart
#banana split" | sed '/apple/ { s/apple/peach/; t; s/pie/cobbler/; }'
#Output:
#peach cobbler
#peach tart
#banana split

#First, we target lines containing “apple” with the /apple/ address.
#Inside the curly braces {}, we make a series of commands to execute.
#The s/apple/peach/ command replaces “apple” with “peach”.
#The t command checks if the above substitution was successful. If it was, it branches to the end of the commands inside the curly braces, skipping the next command. If no substitution was done, it continues executing the subsequent commands.
#The s/pie/cobbler/ command is only executed if the previous s/apple/peach/ substitution wasn’t done.

#Check pattern
#1) If host all all 0.0.0.0\/0 md5 presents in file - do nothing.
#2) If not: check commented or not
#2.1) if commented - cut "host all all 0.0.0.0\/0 md5" and replace
#2.2) if not just append "host all all 0.0.0.0\/0 md5" to the end
#
# sed doc:
# 1) Consider example sed -n -e '1i Header' -e '$a Trailer' <FILE>
#   '1i Header'  : here pattern "1" matches 1st line and command "i" inserts 'Header' before it
#   '$a Trailor' : here pattern "$" matches last line and command "a" appends 'Trailor' after it
# 2) The "t" command checks if the previous substitution was successful. If it was, it goto  to the end of the block , skipping the next commands.
function pg_hba_conf_add_policy() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    dt_exec_or_echo "if grep -qE '^\s*host\s+all\s+all\s+0.0.0.0/0\s+md5\s*$' \"${PG_HBA_CONF}\"; then return 0; fi"
    dt_exec_or_echo "sed -i -E -e 's/^\s*#\s*host\s+all\s+all\s+0.0.0.0\/0\s+md5\s*$/host all all 0.0.0.0\/0 md5/; t; \$a host all all 0.0.0.0\/0 md5' ${PG_HBA_CONF}"
  )
}

function pg_conf_set_port() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    dt_exec_or_echo "sed -i -E -e \"s/^\s*#?\s*(port\s*=\s*[0-9]+)\s*$/port = ${PGPORT}/\" \"${PG_CONF}\""
  )
}

function ctx_service_pg() {
  PGHOST="localhost"
  PGPORT=5432
  PG_MAJOR=17
  PG_MINOR=4
  PG_VERSION="${PG_MAJOR}.${PG_MINOR}"
  PG_DIR=$(pg_dir _); exit_on_err $0 $? || return $?
  PATH=$(pg_new_path _); exit_on_err $0 $? || return $?
  PG_SERVICE=$(pg_service _); exit_on_err $0 $? || return $?

  # Depends on PG_SERVICE and
  PG_HBA_CONF=$(pg_hba_conf _); exit_on_err $0 $? || return $?
  PG_CONF=$(pg_conf _); exit_on_err $0 $? || return $?

  # Depends on PATH
  PG_CONFIG_LIBDIR="$(pg_config --pkglibdir | tr ' ' '\n')"; exit_on_err $0 $? || return $?
  PG_CONFIG_SHAREDIR="$(pg_config --sharedir)"; exit_on_err $0 $? || return $?
  
  _export_envs=(
    PG_CONF
    PG_CONFIG_LIBDIR
    PG_CONFIG_SHAREDIR
    PG_DIR
    PG_HBA_CONF
    PG_MAJOR
    PG_MINOR
    PG_SERVICE
    PG_VERSION
    PGHOST
    PGPORT
  )
  _inline_envs=()
}

function pg_user_admin() {
  PGPASSWORD="postgres"
  if [ "$(os_name)" = "macos" ]; then
    PGUSER="${USER}"
  else
    PGUSER=postgres
  fi
}

function pg_db_postgres() {
  PGDATABASE="postgres"
}

function service_pg_stop() {
  (
    ctx_service_pg
    SERVICE=${PG_SERVICE}
    service_stop $ctx
  )
}

function service_pg_start() {
  (
    ctx_service_pg
    SERVICE=${PG_SERVICE}
    service_start $ctx
  )
}

function lsof_pg() {
  (
    ctx_service_pg
    PORT=${PGPORT}; HOST=${PGHOST}
    lsof_tcp
  )
}