if [ -n "${BASH_SOURCE}" ]; then self="${BASH_SOURCE[0]}"; else self="$0"; fi
self_dir=$(dirname $(realpath "${self}"))
dt_rc_load $(basename "${self_dir}") "${self_dir}"
