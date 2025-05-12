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
  cmd=(cargo install)
  if [ -z "${CRATE_NAME}" ]; then return 99; fi
  if [ -n "${CRATE_VERSION}" ]; then cmd+=(--version "${CRATE_VERSION}"); fi
  cargo_common_flags
  cmd+=(${CRATE_NAME})
  echo "${cmd}"
}

function cargo_uninstall() {
  cmd=(cargo uninstall)
  if [ -z "${CRATE_NAME}" ]; then return 99; fi
  cargo_common_flags
  cmd+=(${CRATE_NAME})
  echo "${cmd}"
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

  # BINS_DIR depends on CARGO_TARGET_DIR, CARGO_TARGET_DIR, BUILD_MODE
  BINS_DIR=

  _envs+=(
    CARGO_BUILD_TARGET
    CARGO_TARGET_DIR
    RUSTFLAGS
  )

  # by default inline all env
  _inline_envs=(${_envs[@]})
}

function cargo_profile() {
  profile="dev"

  if [ "$(get_profile release)" = "release" ]; then
      profile="release"
  fi
  echo "profile"
}

function cargo_build_mode() {
  mode="debug"
  if [ "$(get_profile release)" = "release" ]; then
      mode="release"
  fi
  echo "$mode"
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

function cargo_flag_all_features() {
  FLAGS+=(--all-features)
}

function cargo_flag_no_default_features() {
  FLAGS+=(--no-default-features)
}

function cargo_flag_locked() {
  FLAGS+=(--locked)
}

function cargo_flag_offline() {
  FLAGS+=(--offline)
}

function cargo_flag_frozen() {
  FLAGS+=(--frozen)
}

function cargo_flag_ignore_rust_version() {
  FLAGS+=(--ignore-rust-version)
}

function cargo_flag_force() {
  FLAGS+=(--force)
}

function cd_manifest_dir() {
  if [ ! -d "${MANIFEST_DIR}" ]; then return 99; fi
  cd "${MANIFEST_DIR}"
}

function cargo_pkg_selection() {
  if [ -n "${PACKAGE}" ]; then
    # If package is specified use --package
    cmd+=(--package "${PACKAGE}")
  else
    # If package is NOT specified use --workspace with --exclude
    cmd+=(--workspace)
    for exc in ${EXCLUDE}; do
      cmd+=(--exclude ${exc})
    done
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
  if [ -z "${BINS}" ]; then return 0; fi
  for bin in ${BINS}; do
    cmd+=(--bin "${bin}")
  done
}

function cargo_common_flags() {
  if [ -n "${FLAGS}" ]; then
    for flag in ${FLAGS}; do
      cmd+=(${flag})
    done
  fi
}

function cargo_common_opts() {
  if [ -n "${FEATURES}" ]; then cmd+=(--features "'${FEATURES}'"); fi
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
  cargo_common_flags
  cargo_common_opts
}

# ctx_CMD_CTX
# ctx_cargo_CTX
# ctx_cargo
function cargo_build() {
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo build)
  cargo_gen_cli
  echo "${cmd}"
}

function cargo_fmt() {
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo fmt)
  cargo_gen_cli
  echo "${cmd}"
}

function cargo_fmt() {
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo)
  if [ -n "${NIGHTLY_VERSION}" ]; then cmd+="+${NIGHTLY_VERSION}"; fi
  cmd+=(fmt)
  cargo_gen_cli
  cmd+=(-- --check)
  echo "${cmd}"
}

function cargo_fmt_fix() {
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo)
  if [ -n "${NIGHTLY_VERSION}" ]; then cmd+="+${NIGHTLY_VERSION}"; fi
  cmd+=(fmt)
  cargo_gen_cli
  echo "${cmd}"
}

function cargo_test() {
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo test)
  cargo_gen_cli
  echo "${cmd}"
}

# "cargo clippy" uses "cargo check" under the hood.
function cargo_clippy() {
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo clippy)
  cargo_gen_cli
  cargo_clippy_opts
  echo "${cmd}"
}

function cargo_clippy_fix() {
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo clippy)
  cargo_gen_cli
  cmd+=(--fix --allow-staged)
  cargo_clippy_opts
  echo "${cmd}"
}

function cargo_doc() {
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo doc)
  cargo_gen_cli
  cmd+=(--no-deps --document-private-items)
  echo "${cmd}"
}

function cargo_doc_open() {
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo doc)
  cargo_gen_cli
  cmd+=(--no-deps --document-private-items --open)
  echo "${cmd}"
}

function cargo_clean() {
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo clean)
  if [ -n "${PACKAGE}" ]; then
    cmd+=(--package "${PACKAGE}")
  fi
  echo "${cmd}"
}
