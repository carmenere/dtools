function pg_add_path() {
  $(echo ${PATH} | grep -E -s "^$(pg_dir)" 1>/dev/null 2>&1)
  if [ $? != 0 ] && [ -n "$(pg_dir)" ]; then PATH="$(pg_dir):${PATH}"; fi
}

function pg_hba() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/$(pg_service)/pg_hba.conf"
  else
    echo "/etc/postgresql/${PG_MAJOR}/main/pg_hba.conf"
  fi
}

function pg_conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/$(pg_service)/postgresql.conf"
  else
    echo "/etc/postgresql/${PG_MAJOR}/main/postgresql.conf"
  fi
}

function pg_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "postgresql@${PG_MAJOR}"
  else
    echo postgresql
  fi
}

function pg_install() {
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      echo "deb http://apt.postgresql.org/pub/repos/apt ${OS_CODENAME}-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
      sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
      sudo apt-get update
      sudo apt-get -y install \
          postgresql-${PG_MAJOR} \
          postgresql-server-dev-${PG_MAJOR} \
          libpq-dev

  elif [ "$(os_kernel)" = "Darwin" ]; then
    brew install "${SERVICE}"
  else
    echo "Unsupported OS: '$(os_kernel)'"; exit;
  fi
}

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
function pg_hba_add_policy() {
  dt_cmd "if grep -qE '^\s*host\s+all\s+all\s+0.0.0.0/0\s+md5\s*$' \"$(pg_hba)\"; then return 0; fi"
  dt_cmd "sed -i -E -e 's/^\s*#\s*host\s+all\s+all\s+0.0.0.0\/0\s+md5\s*$/host all all 0.0.0.0\/0 md5/; t; \$a host all all 0.0.0.0\/0 md5' $(pg_hba)"
}

function pg_conf_set_port() {
  dt_cmd "sed -i -E -e \"s/^\s*#?\s*(port\s*=\s*[0-9]+)\s*$/port = ${PGPORT}/\" \"$(pg_conf)\""
}

function pg_dir() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/opt/postgresql@${PG_MAJOR}/bin"
  elif [ "$(os_name)" = "alpine" ]; then
    echo "/usr/libexec/postgresql${PG_MAJOR}"
  else
    echo "/usr/lib/postgresql/${PG_MAJOR}/bin"
  fi
}

function pg_stop() {
  ( ctx_pg; service_stop )
}

function pg_start() {
  ( ctx_pg; service_start )
}

function pg_lsof() {
  (
    ctx_pg; PORT=${PGPORT}; HOST=${PGHOST}
    lsof_tcp
  )
}

function ctx_pg() {
  pg_add_path
  PGHOST="localhost"
  PGPORT=5432
  PG_CONF=$(pg_conf)
  PG_DIR=$(pg_dir)
  PG_HBA=$(pg_hba)
  PG_MAJOR=17
  PG_MINOR=4
  SERVICE=$(pg_service)
  PG_CFG_LIBDIR="$(pg_config --pkglibdir | tr ' ' '\n')"
  PG_CFG_SHAREDIR="$(pg_config --sharedir)"

  # Depends on PG_MAJOR and PG_MINOR
  PG_VERSION="${PG_MAJOR}.${PG_MINOR}"

  _envs=(PGHOST PGPORT)
  _inline_envs=(${_envs[@]})
}

function pg_user_admin() {
  PGPASSWORD="postgres"
  if [ "$(os_name)" = "macos" ]; then
    PGUSER="${USER}"
  else
    PGUSER=postgres
  fi
  _envs+=(PGUSER PGPASSWORD)
  _inline_envs=(${_envs[@]})
}

function pg_db_postgres() {
  PGDATABASE="postgres"
  _envs+=(PGDATABASE)
  _inline_envs=(${_envs[@]})
}


