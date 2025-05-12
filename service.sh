function service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "brew services"
  else
    echo "systemctl"
  fi
}

function service_stop() {
  if [ -z "$1" ]; then echo "Service name was not provided."; return 99; fi
  dt_cmd "$(service) stop $1"
}

function service_start() {
  if [ -z "$1" ]; then echo "Service name was not provided."; return 99; fi
  dt_cmd "$(service) start $1"
}
