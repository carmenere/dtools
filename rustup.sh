function rust_version() {
  echo "1.99.0"
}

function rust_nightly_version() {
  echo "nightly-2025-05-01"
}

function rust_arch() {
  arch=$(uname -m)
  if [ "${arch}" = "arm64" ]; then
    arch="aarch64"
  fi
  echo $arch
}

function rust_target_triple() {
  if [ "$(os_name)" = "ubuntu" ]; then
    echo "$(rust_arch)-unknown-linux-gnu"
  elif [ "$(os_name)" = "alpine" ]; then
    echo "$(rust_arch)-unknown-linux-musl"
  elif [ "$(os_name)" = "macos" ]; then
    echo "$(rust_arch)-apple-darwin"
  elif [ "$(os_kernel)" = "Linux" ]; then
    echo "x86_64-unknown-linux-gnu"
  fi
}

function rustup_install() {
  toolchain=$(rust_version)-$(rust_target_triple)
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "${toolchain}"
}

function rustup_toolchain_install() {
  toolchain=$1; if [ -z "${toolchain} "]; then toolchain=$(rust_version)-$(rust_target_triple); fi
	rustup toolchain install "${toolchain}"
}

function rustup_default() {
  toolchain=$1; if [ -z "${toolchain}" ]; then toolchain=$(rust_version)-$(rust_target_triple); fi
	rustup default "${toolchain}"
}

function rustup_component_add() {
  components=$1; if [ -z "$components" ]; then components="clippy rustfmt"; fi
	rustup +$(V) component add "${components}"
}

function rustup_envs() {
  RUSTUP_TOOLCHAIN=$(rust_version)
}
