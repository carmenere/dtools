function cargo_cache_clean() {
  cargo cache -r all
}

# Example
#function ctx_crate_sqlx() {
#  CRATE_NAME="sqlx-cli"
#  CRATE_VERSION="0.8.5"
#  cargo_flag_locked
#}

function cargo_install() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    cmd=(cargo install)
    if [ -z "${CRATE_NAME}" ]; then return 99; fi
    if [ -n "${CRATE_VERSION}" ]; then cmd+=(--version "${CRATE_VERSION}"); fi
    cargo_manifest_opts
    cmd+=(${CRATE_NAME})
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_uninstall() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    cmd=(cargo uninstall)
    if [ -z "${CRATE_NAME}" ]; then return 99; fi
    cargo_manifest_opts
    cmd+=(${CRATE_NAME})
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_profile() {
  profile="dev"

  if [ "$(get_profile release)" = "release" ]; then
      profile="release"
  fi
  echo "${profile}"
}

function cargo_build_mode() {
  mode="debug"
  if [ "$(get_profile release)" = "release" ]; then
      mode="release"
  fi
  echo "${mode}"
}

# BINS_DIR can be:
#   ${CARGO_TARGET_DIR}/${CARGO_BUILD_TARGET}/${BUILD_MODE}
#   ${CARGO_TARGET_DIR}/${BUILD_MODE}
function cargo_bin_dir() {
  if [ -n "${CARGO_TARGET_DIR}" ]; then
    bin_dir="${CARGO_TARGET_DIR}"
  else
    bin_dir="$(pwd)/target"
  fi
  if [ -n "${CARGO_BUILD_TARGET}" ]; then bin_dir="${bin_dir}/${CARGO_BUILD_TARGET}"; fi
  if [ -n "${BUILD_MODE}" ]; then
    bin_dir="${bin_dir}/${BUILD_MODE}"
  else
    bin_dir="${bin_dir}/$(cargo_build_mode)"
  fi
  echo "${bin_dir}"
}

function cd_manifest_dir() {
  if [ ! -d "${MANIFEST_DIR}" ]; then return 99; fi
  cd "${MANIFEST_DIR}"
}

function cargo_pkg_selection() {
  if [ -n "${PACKAGE}" ]; then
    # If package is specified use --package
    cmd+=(--package "${PACKAGE}")
  fi
}

function cargo_workspace_opts() {
  if [ -z "${PACKAGE}" ]; then
    # If package is NOT specified use --workspace with --exclude
    cmd+=(--workspace)
    for exc in ${EXCLUDE}; do
      cmd+=(--exclude ${exc})
    done
  fi
}

function cargo_target_selection() {
  # By default: --bins --lib
  # When no target selection options are given, cargo build will build all binary and library targets of the selected packages.
  # Binaries are skipped if they have required-features that are missing.
  if [ -z "${BINS}" ]; then return 0; fi
  for bin in ${BINS}; do
    cmd+=(--bin "${bin}")
  done
}

function cargo_manifest_opts() {
  if [ "${FROZEN}" = "y" ]; then cmd+=(--frozen); fi
  if [ "${LOCKED}" = "y" ]; then cmd+=(--locked); fi
  if [ "${OFFLINE}" = "y" ]; then cmd+=(--offline); fi
  if [ "${FORCE}" = "y" ]; then cmd+=(--force); fi
  if [ "${IGNORE_RUST_VERSION}" = "y" ]; then cmd+=(--ignore-rust-version); fi
}

function cargo_feature_selection() {
  if [ "${NO_DEFAULT_FEATURES}" = "y" ]; then cmd+=(--no-default-features); fi
  if [ "${ALL_FEATURES}" = "y" ]; then cmd+=(--all-features); fi
  if [ -n "${FEATURES}" ]; then cmd+=(--features "'${FEATURES}'"); fi
}

function cargo_common_opts() {
  if [ -n "${MESSAGE_FORMAT}" ]; then cmd+=(--message-format "${MESSAGE_FORMAT}"); fi
  if [ -n "${PROFILE}" ]; then cmd+=(--profile "${PROFILE}"); fi
}

function cargo_clippy_opts() {
  OPTS=()
  if [ -n "${CLIPPY_LINTS}" ]; then OPTS+=("'${CLIPPY_LINTS}'"); fi
  if [ -n "${CLIPPY_REPORT}" ]; then OPTS+=("1>${CLIPPY_REPORT}"); fi
  if [ -n "${OPTS}" ]; then cmd+=(-- "${OPTS}"); fi
}

function cargo_gen_cli() {
  cargo_pkg_selection
  cargo_workspace_opts
  cargo_target_selection
  cargo_feature_selection
  cargo_manifest_opts
  cargo_common_opts
}

function cargo_build() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo build)
    cargo_gen_cli
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_fmt() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo)
    if [ -n "${NIGHTLY_VERSION}" ]; then cmd+="+${NIGHTLY_VERSION}"; fi
    cmd+=(fmt)
    cargo_pkg_selection
    cargo_manifest_opts
    cmd+=(-- --check)
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_fmt_fix() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo)
    if [ -n "${NIGHTLY_VERSION}" ]; then cmd+="+${NIGHTLY_VERSION}"; fi
    cmd+=(fmt)
    cargo_pkg_selection
    cargo_manifest_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_test() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo test)
    cargo_gen_cli
    dt_exec_or_echo "${cmd}" $mode
  )
}

# "cargo clippy" uses "cargo check" under the hood.
function cargo_clippy() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo clippy)
    cargo_gen_cli
    cargo_clippy_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_clippy_fix() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo clippy)
    cargo_gen_cli
    cmd+=(--fix --allow-staged)
    cargo_clippy_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_doc() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo doc)
    cargo_gen_cli
    cmd+=(--no-deps --document-private-items)
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_doc_open() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo doc)
    cargo_gen_cli
    cmd+=(--no-deps --document-private-items --open)
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_clean() {
  (
    dt_check_ctx $@
    $ctx; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo clean)
    if [ -n "${PACKAGE}" ]; then
      cmd+=(--package "${PACKAGE}")
    fi
    dt_exec_or_echo "${cmd}" $mode
  )
}

# BINS is an array, by default BINS=()
# FLAGS is an array, by default FLAGS=()
# FLAGS may contain (| means or/and):
#   --all-features | --no-default-features | --offline | --locked | --frozen | --ignore-rust-version
function ctx_cargo() {
  ctx_rustup
  # inherited from ctx_rustup
  #  RUSTUP_TOOLCHAIN=
  #  NIGHTLY_VERSION=
  # _envs
  BINS=()
  BUILD_MODE=$(cargo_build_mode)
  CARGO_BUILD_TARGET=
  CARGO_TARGET_DIR="$(pwd)/target"
  CLIPPY_LINTS=()
  CLIPPY_REPORT=
  EXCLUDE=()
  FEATURES=()
  FLAGS=()
  MANIFEST='Cargo.toml'
  MANIFEST_DIR=
  MESSAGE_FORMAT=
  PACKAGE=
  PROFILE=$(cargo_profile)
  RUSTFLAGS=''

  # Flags, can be y or n
  ALL_FEATURES=
  FORCE=
  FROZEN=
  IGNORE_RUST_VERSION=
  LOCKED=
  NO_DEFAULT_FEATURES=
  OFFLINE=

  # BINS_DIR depends on CARGO_TARGET_DIR, CARGO_TARGET_DIR, BUILD_MODE
  BINS_DIR=$(cargo_bin_dir)

  _envs+=(CARGO_BUILD_TARGET CARGO_TARGET_DIR RUSTFLAGS)
  # by default inline all env
  _inline_envs=(${_envs[@]})
}