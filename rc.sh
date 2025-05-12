# To run dev_tools outside of project root directory env DT_PROJECT_DIR must be exported and contain absolute path
# to the project root directory before run.
# If DT_PROJECT_DIR is empty the parent of closest ".git" directory will be used.
if [ -z "${DT_PROJECT_DIR}" ]; then
  gdir="$(git rev-parse --git-dir)" || return $?
  export DT_PROJECT_DIR="$(realpath ${gdir}/..)"
fi



# Sdpecial vars
export DT_PROFILES=("dev")
export DT_EXPORTS=()
#export DT_DEBUG=yes
export DT_DEBUG=

dt_rc_load lib "$(dirname "$0")"
