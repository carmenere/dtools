function cargo_pkg_opt() {
  if [ -n "${PACKAGE}" ]; then
    # If package is specified use --package
    cmd+=(--package "${PACKAGE}")
  fi
}

function cargo_workspace_opt() {
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

function cargo_shared_manifest_opts() {
  if [ "${FROZEN}" = "y" ]; then cmd+=(--frozen); fi
  if [ "${LOCKED}" = "y" ]; then cmd+=(--locked); fi
  if [ "${OFFLINE}" = "y" ]; then cmd+=(--offline); fi
}

function cargo_features_opts() {
  if [ "${ALL_FEATURES}" = "y" ]; then cmd+=(--all-features); fi
  if [ "${NO_DEFAULT_FEATURES}" = "y" ]; then cmd+=(--no-default-features); fi
  if [ -n "${FEATURES}" ]; then cmd+=(--features "'${FEATURES}'"); fi
}

function cargo_install_opts() {
  cargo_shared_manifest_opts
  if [ "${FORCE}" = "y" ]; then cmd+=(--force); fi
}

function cargo_uninstall_opts() {
  cargo_shared_manifest_opts
}

function cargo_fmt_opts() {
  cargo_pkg_opt
  if [ -n "${MESSAGE_FORMAT}" ]; then cmd+=(--message-format "${MESSAGE_FORMAT}"); fi
  if [ -n "${MANIFEST_PATH}" ]; then cmd+=(--manifest-path "${MANIFEST_PATH}"); fi
}

function cargo_shared_build_check_test_doc_opts() {
  cargo_pkg_opt
  cargo_workspace_opt
  cargo_target_selection
  cargo_features_opts
  if [ "${IGNORE_RUST_VERSION}" = "y" ]; then cmd+=(--ignore-rust-version); fi
  if [ -n "${MESSAGE_FORMAT}" ]; then cmd+=(--message-format "${MESSAGE_FORMAT}"); fi
  if [ -n "${PROFILE}" ]; then cmd+=(--profile "${PROFILE}"); fi
  if [ -n "${MANIFEST_PATH}" ]; then cmd+=(--manifest-path "${MANIFEST_PATH}"); fi
}

function cargo_build_opts() {
  cargo_shared_manifest_opts
  cargo_shared_build_check_test_doc_opts
}

function cargo_clippy_opts() {
  cargo_shared_manifest_opts
  cargo_shared_build_check_test_doc_opts
}

function cargo_test_opts() {
  cargo_shared_manifest_opts
  cargo_shared_build_check_test_doc_opts
}

function cargo_doc_opts() {
  cargo_shared_manifest_opts
  cargo_shared_build_check_test_doc_opts
}

function cargo_clean_opts() {
  cargo_pkg_opt
  cargo_shared_manifest_opts
  if [ -n "${PROFILE}" ]; then cmd+=(--profile "${PROFILE}"); fi
  if [ -n "${MANIFEST_PATH}" ]; then cmd+=(--manifest-path "${MANIFEST_PATH}"); fi
}

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
    if [ -z "${CRATE_NAME}" ]; then dt_error $0 "Var CRATE_NAME is empty"; return 99; fi
    if [ -z "${CRATE_VERSION}" ]; then dt_error $0 "Var CRATE_VERSION is empty"; return 99; fi
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd=(cargo install)
    cmd+=(--version "${CRATE_VERSION}")
    cargo_install_opts
    cmd+=(${CRATE_NAME})
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_uninstall() {
  (
    if [ -z "${CRATE_NAME}" ]; then dt_error $0 "Var CRATE_NAME is empty"; return 99; fi
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd=(cargo uninstall)
    cargo_uninstall_opts
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

function cargo_build() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo build)
    cargo_build_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_fmt() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo)
    if [ -n "${NIGHTLY_VERSION}" ]; then cmd+=("+${NIGHTLY_VERSION}"); fi
    cmd+=(fmt)
    cargo_fmt_opts
    cmd+=(-- --check)
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_fmt_fix() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo)
    if [ -n "${NIGHTLY_VERSION}" ]; then cmd+=("+${NIGHTLY_VERSION}"); fi
    cmd+=(fmt)
    cargo_fmt_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_test() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo test)
    cargo_test_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

# "cargo clippy" uses "cargo check" under the hood.
function cargo_clippy() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo clippy)
    cargo_clippy_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_clippy_fix() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo clippy --fix --allow-staged)
    cargo_clippy_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_doc() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo doc --no-deps --document-private-items)
    cargo_doc_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_doc_open() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo doc --no-deps --document-private-items --open)
    cargo_doc_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

function cargo_clean() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    cmd=("$(dt_inline_envs)")
    cmd+=(cargo clean)
    cargo_clean_opts
    dt_exec_or_echo "${cmd}" $mode
  )
}

# BINS is an array, by default BINS=()
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
  MANIFEST='Cargo.toml'
  MANIFEST_DIR=
  MANIFEST_PATH=
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

  # MANIFEST_PATH depends on both MANIFEST and MANIFEST_DIR
  if [ -n "${MANIFEST_DIR}" ] && [ -n "${MANIFEST}" ]; then MANIFEST_PATH="${MANIFEST_DIR}/${MANIFEST}"; fi

  _envs+=(CARGO_BUILD_TARGET CARGO_TARGET_DIR RUSTFLAGS)
  # by default inline all env
  _inline_envs=(${_envs[@]})
}