if [ -n "${BASH_SOURCE}" ]; then self="${BASH_SOURCE[0]}"; else self="$0"; fi
clickhouse_dir=$(dirname $(realpath "${self}"))
dt_rc_load $(basename "${clickhouse_dir}") "${clickhouse_dir}"
