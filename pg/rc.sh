if [ -n "${BASH_SOURCE}" ]; then self="${BASH_SOURCE[0]}"; else self="$0"; fi
pg_dir=$(dirname $(realpath "${self}"))
dt_rc_load $(basename "${pg_dir}") "${pg_dir}"
