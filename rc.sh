# Sdpecial vars
export DT_PROFILES=("dev")
#export DT_DEBUG=yes
export DT_DEBUG=

# The "lib.sh" must be loaded before!
dt_rc_load core $(dirname $(realpath "$0"))
