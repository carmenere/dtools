if [ -n "${BASH_SOURCE}" ]; then self="${BASH_SOURCE[0]}"; else self="$0"; fi

# The "lib.sh" must be loaded before!
dt_rc_load core $(dirname $(realpath "$self"))
