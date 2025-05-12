function service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "brew services"
  else
    echo "systemctl"
  fi
}

function service_stop() {
  if [ -z "{$SERVICE}" ]; then echo "Service name was not provided."; return 99; fi
  echo "$(service) stop {$SERVICE}"
}

function service_start() {
  if [ -z "${$SERVICE}" ]; then echo "Service name was not provided."; return 99; fi
  echo "$(service) start {$SERVICE}"
}
