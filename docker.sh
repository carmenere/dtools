#  FULL NAME: REGISTRY[:PORT]/[r|_]/NAMESPACE/REPO[:TAG]

function ctx_docker_network() {
  SUBNET="192.168.111.0/24"
  BRIDGE="foobar"
  ERR_IF_BRIDGE_EXISTS="n"
  DRIVER="bridge"
}

# Doc:
#  NO_CACHE build without any cache
ctx_docker_image() {
  DEFAULT_IMAGE="alpine:3.21"
  BUILD_ARGS=
  CTX="."
  DEFAULT_TAG=$(docker_default_tag)
  DOCKERFILE=
  IMAGE=
  NO_CACHE=
  REGISTRY="example.com"

  # Depends on DEFAULT_IMAGE and REGISTRY
  BASE_IMAGE=$(docker_base_image)
  _build_args=()
  _export_envs=()
  _inline_envs=(${_export_envs[@]})
}

# Doc:
#   ATTACH: attach docker to current terminal (to STDIN, STDOUT or STDERR)
#   BACKGROUND: run in background
#   PSEUDO_TTY: allocate a pseudo-TTY
#   REGISTRY="example.com:5004"
#   RESTART="always"|"no"
#   RM: remove after stop
#   STDIN: keep STDIN open even if not attached
#   PUBLISH=()
#   PUBLISH+=("${PORT_11}:${PORT_33}/tcp")
#   PUBLISH+=("${PORT_22}:${PORT_44}/tcp")
#   _app_envs=()
#   _app_envs+=(XXX)
#   _app_envs+=(YYY)
#   _build_args=()
#   _build_args+=(XXX)
#   _build_args+=(YYY)
# ENVS = "--env POSTGRES_PASSWORD=${ADMIN_PASSWORD} --env POSTGRES_DB=${ADMIN_DB} --env POSTGRES_USER=${ADMIN}"
ctx_docker_container() {
  ctx_docker_network
  ATTACH=
  BACKGROUND=
  PSEUDO_TTY=
  PUBLISH=()
  REGISTRY=
  RESTART=
  RM=
  SH="/bin/sh"
  STDIN=
  COMMAND=
  CONTAINER=
  _app_envs=()
  _export_envs=()
  _inline_envs=(${_export_envs[@]})
}

function docker_install() {
  SUDO=sudo
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      ${SUDO} apt-get update
      ${SUDO} apt-get install -y ca-certificates curl gnupg
      ${SUDO} install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${SUDO} gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      ${SUDO} chmod a+r /etc/apt/keyrings/docker.gpg
      echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "${VERSION_CODENAME}")" stable" | \
      ${SUDO} tee /etc/apt/sources.list.d/docker.list > /dev/null
      ${SUDO} apt-get update
      ${SUDO} apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  else
    echo "Unsupported OS: '${OS_NAME}'"; exit;
  fi
}

function docker_post_install() {
  # post-install actions
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      ${SUDO} groupadd docker || true
      ${SUDO} usermod -aG docker ${USER}
  fi
}

function docker_base_image() {
  bi="${REGISTRY}/build/${DEFAULT_IMAGE}"
  if [ "$(uname -m)" = "arm64" ]; then
    bi="arm64v8/${DEFAULT_IMAGE}"
  fi
  echo $bi
}

function docker_default_tag() {
  tag="v0.0.1"
  if [ "$(uname -m)" = "arm64" ]; then
    tag="v0.0.1-arm64"
  fi
  echo $tag
}

function docker_pull_opts() {
  if [ -n "${IMAGE}"]; then cmd+=("${IMAGE}"); dt_error $0 "Var 'IMAGE' is empty"; return 99; fi
}

function docker_build_opts() {
  if [ -z "${DOCKERFILE}"]; then dt_error $0 "Var 'DOCKERFILE' is empty"; return 99; fi
  if [ -z "${IMAGE}"]; then dt_error $0 "Var 'IMAGE' is empty"; return 99; fi
  if [ -z "${CTX}"]; then dt_error $0 "Var 'CTX' is empty"; return 99; fi

  if [ "${NO_CACHE}" = "y" ]; then cmd+=(--no-cache); fi
  cmd+=(-f "${DOCKERFILE}")
  cmd+=(-t "${IMAGE}")
  cmd+=("${CTX}")
}

function docker_run_opts() {
  if [ -z "${IMAGE}" ]; then dt_error $0 "Var 'IMAGE' is empty"; return 99; fi
  if [ "${ATTACH}" = "y" ]; then cmd+=(-a); fi
  if [ "${BACKGROUND}" = "y" ]; then cmd+=(-d); fi
  if [ "${PSEUDO_TTY}" = "y" ]; then cmd+=(-t); fi
  if [ "${RM}" = "y" ]; then cmd+=(--rm); fi
  if [ "${STDIN}" = "y" ]; then cmd+=(-i); fi
  if [ -n "${BRIDGE}" ]; then cmd+=(--network "${BRIDGE}"); fi
  if [ -n "${CONTAINER}" ]; then cmd+=(--name "${CONTAINER}"); fi
  if [ -n "${RESTART}" ]; then cmd+=(--restart "${RESTART}"); fi

  if [ -n "${IMAGE}" ]; then cmd+=("${IMAGE}"); fi
  if [ -n "${COMMAND}" ]; then cmd+=("${COMMAND}"); fi
}

function docker_run_publish_opts() {
  if [ -z "${PUBLISH}" ]; then return 0; fi
  for publish in ${PUBLISH}; do
    cmd+=(--publish "${publish}")
  done
}

function docker_run_env_opts() {
  for e in ${_app_envs}; do
    if [ -z "$e" ]; then continue; fi
    val=$(dt_escape_single_quotes "$(eval echo "\$$e")")
    if [ -n "${val}" ]; then cmd+=(--env "${e}=$'${val}'"); fi
  done
}

function docker_build_arg_opts() {
  for arg in ${_build_args}; do
    if [ -z "$arg" ]; then continue; fi
    val=$(dt_escape_single_quotes "$(eval echo "\$$arg")")
    if [ -n "${val}" ]; then cmd+=(--build-arg "${arg}=$'${val}'"); fi
  done
}

function docker_pull() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(docker pull ${IMAGE})
    docker_pull_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function docker_build() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(docker build)
    docker_build_arg_opts
    docker_build_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function docker_check() {
  if ! docker ps 1>/dev/null; then dt_error $0 "Service docker is not run"; fi
}

function docker_exec() {
  docker_check; exit_on_err $0 $? || return $?
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=(docker exec -ti ${CONTAINER} ${SH})
    dt_exec_or_echo "${cmd}" $mode
  )
}

function docker_network_create() {
  docker_check; exit_on_err $0 $? || return $?
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ ${ERR_IF_BRIDGE_EXISTS} = "y" ]; then
      if [ -n "$(docker network ls -q --filter name="^${BRIDGE}$")" ]; then dt_error $0 "Bridge ${BRIDGE} exists."; return 99; fi
    else
      if [ -n "$(docker network ls -q --filter name="^${BRIDGE}$")" ]; then return 0; fi
      cmd=(docker network create --driver=${DRIVER} --subnet=${SUBNET} ${BRIDGE})
      dt_exec_or_echo "${cmd}" $mode
    fi
  )
}

function docker_network_rm() {
  docker_check; exit_on_err $0 $? || return $?
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ -z "$(docker network ls -q --filter name="^${BRIDGE}$")" ]; then return 0; fi
    cmd=(docker network rm ${BRIDGE})
    dt_exec_or_echo "${cmd}" $mode
  )
}

function docker_network_ls() {
  docker_check; exit_on_err $0 $? || return $?
  cmd=(docker network ls)
  dt_exec_or_echo "${cmd}" $mode
}

function docker_run() {
  docker_check; exit_on_err $0 $? || return $?
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ -n "$(docker ps -aq --filter name="^${CONTAINER}$")" ]; then return 0; fi
#    docker_network_create $ctx; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(docker run)
    docker_run_publish_opts
    docker_run_env_opts
    docker_run_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function docker_start() {
  docker_check; exit_on_err $0 $? || return $?
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ -n "$(docker ps -aq --filter name="^${CONTAINER}$" --filter status=exited --filter status=created)" ]; then
      cmd=(docker start ${CONTAINER})
      dt_exec_or_echo "${cmd}" $mode
    elif [ -z "$(docker ps -aq --filter name="^${CONTAINER}$")" ]; then
      docker_run
    else
      dt_info "Running container '${CONTAINER}'"
    fi
  )
}

function docker_stop() {
  docker_check; exit_on_err $0 $? || return $?
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ -z "$(docker ps -aq --filter name="^${CONTAINER}$" --filter status=running)" ]; then return 0; fi
    cmd=(docker stop ${CONTAINER})
    dt_exec_or_echo "${cmd}" $mode
  )
}
function docker_rmi() {
  docker_check; exit_on_err $0 $? || return $?
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=(docker rmi ${IMAGE})
    dt_exec_or_echo "${cmd}" $mode
  )
}

function docker_rm() {
  docker_check; exit_on_err $0 $? || return $?
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ -z "$(docker ps -aq --filter name="^${CONTAINER}$")" ]; then return 0; fi
    cmd=(docker rm --force ${CONTAINER})
    dt_exec_or_echo "${cmd}" $mode
  )
}

function docker_rm_by_image() {
  docker_check; exit_on_err $0 $? || return $?
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ -z "$(docker ps -aq --filter ancestor="^${IMAGE}$")" ]; then return 0; fi
    cmd=(docker rm --force "$(docker ps -aq --filter ancestor="^${IMAGE}$")")
    dt_exec_or_echo "${cmd}" $mode
  )
}

function docker_status() {
  docker_check; exit_on_err $0 $? || return $?
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=(docker ps --format "'table {{.ID}} | {{.Status}}'" --format name="^${CONTAINER}$")
    dt_exec_or_echo "${cmd}" $mode
  )
}

function docker_logs() {
  docker_check; exit_on_err $0 $? || return $?
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    if [ -z "$(docker ps -aq --filter name="^${CONTAINER}$" --filter status=running)" ]; then return 0; fi
    cmd=(docker logs "${CONTAINER}" '>' "${DT_LOGS}/container-${CONTAINER}.log" '2>&1')
    dt_exec_or_echo "${cmd}" $mode
  )
}

function docker_rm_all() {
  if [ -z "$(docker ps -aq)" ]; then return 0; fi
  cmd=(docker rm --force "$(docker ps -aq)")
  dt_exec_or_echo "${cmd}" $mode
}

function docker_prune() {
  docker_rm_all
  dt_exec_or_echo "docker system prune --force"
  dt_exec_or_echo "docker volume prune --force"
  dt_exec_or_echo "docker network prune --force"
}

function docker_purge() {
  docker_rm_all
  dt_exec_or_echo "docker system prune --force --all --volumes"
  dt_exec_or_echo "docker volume prune --force"
  dt_exec_or_echo "docker network prune --force"
  dt_exec_or_echo "docker builder prune --force --all"
}