function redis_service() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ "$(os_name)" = "macos" ]; then
      echo "redis"
    else
      echo "redis-server"
    fi
  )
}

function redis_install() {
  dt_debug_args "$0" "$*"
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    SUDO=$(_sudo)
    if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
        ${SUDO} apt install lsb-release curl gpg
        curl -fsSL https://packages.redis.io/gpg | ${SUDO} gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb ${OS_CODENAME} main" | ${SUDO} tee /etc/apt/sources.list.d/redis.list
        ${SUDO} apt-get update
        ${SUDO} apt-get -y install redis

    elif [ "$(os_kernel)" = "Darwin" ]; then
      brew install redis@${MAJOR}

    else
      echo "Unsupported OS: '${OS_NAME}'"; exit;
    fi
  )
}

function ctx_service_redis() {
  CONFIG_REWRITE="yes"
  EXIT_IF_USER_EXISTS="no"
  REDIS_HOST="localhost"
  REDIS_MAJOR=7
  REDIS_MINOR=2
  REDIS_PATCH=4
  REDIS_PORT=6379
  REDIS_SERVICE=$(redis_service _); exit_on_err $0 $? || return $?
  REDIS_VERSION="${REDIS_MAJOR}.${REDIS_MINOR}.${REDIS_PATCH}"
  REQUIREPASS="y"

  _export_envs=(
    REDIS_HOST
    REDIS_MAJOR
    REDIS_MINOR
    REDIS_PATCH
    REDIS_PORT
    REDIS_SERVICE
    REDIS_VERSION
  )
}

function redis_user_admin() {
  REDIS_USER="default"
  REDIS_PASSWORD=''
}

function redis_db_0() {
  REDIS_DB=0
}

function service_redis_stop() {
  (
    ctx_service_redis
    SERVICE=${REDIS_SERVICE}
    service_stop $ctx
  )
}

function service_redis_start() {
  (
    ctx_service_redis
    SERVICE=${REDIS_SERVICE}
    service_start $ctx
  )
}

function lsof_redis() {
  (
    ctx_service_redis
    HOST=${REDIS_HOST}
    PORT=${REDIS_PORT}
    lsof_tcp
  )
}
