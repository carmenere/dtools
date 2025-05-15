function ctx_tmux() {
  TMX_DEFAULT_CMD="/bin/bash"
  TMX_DEFAULT_TERM="xterm-256color"
  TMX_HISTORY_LIMIT=1000000
  TMX_TERM_SIZE="240x32"
  # tmux session name
  TMX_SESSION=
  # WINDOW_NAME and START_CMD are different for each APP
  TMX_WINDOW_NAME=
  TMX_START_CMD=
}

function tmux_check_session() {
  if [ -z "${TMX_SESSION}" ]; then echo "Parameter TMX_SESSION is empty, but it must be set. Cannot create window inside tmux." return 0; fi
}

function tmux_check_window_name() {
  if [ -z "${TMX_WINDOW_NAME}" ]; then echo "Parameter TMX_WINDOW_NAME is empty, but it must be set. Cannot create window inside tmux." return 0; fi
}

function tmux_check_start_cmd() {
  if [ -z "${TMX_START_CMD}" ]; then echo "Parameter TMX_START_CMD is empty, but it must be set. Nothing to start." return 0; fi

}

function tmux_new() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    tmux_check_session || return $?
    tmux has-session -t ${TMX_SESSION} || tmux new -s ${TMX_SESSION} -d
    tmux has-session -t ${TMX_SESSION} && \
    tmux set-option -t ${TMX_SESSION} -g default-command ${TMX_DEFAULT_CMD}
    tmux has-session -t ${TMX_SESSION} && \
    tmux set-option -t ${TMX_SESSION} -g default-terminal ${TMX_DEFAULT_TERM}
    tmux has-session -t ${TMX_SESSION} && \
    tmux set-option -t ${TMX_SESSION} -g history-limit ${TMX_HISTORY_LIMIT}
    tmux has-session -t ${TMX_SESSION} && \
    tmux set-option -t ${TMX_SESSION} -g default-size ${TMX_TERM_SIZE}
  )
}

function tmux_close() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    tmux_check_session || return $?
    tmux has-session -t ${TMX_SESSION} && tmux kill-session -t ${TMX_SESSION} || echo "Session ${TMX_SESSION} was not opened."
  )
}

function tmux_start_sync() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    tmux_new $ctx
    tmux_check_window_name || return $?
    tmux_check_start_cmd || return $?
    tmux select-window -t ${TMX_SESSION}:${TMX_WINDOW_NAME} || tmux new-window -t ${TMX_SESSION} -n ${TMX_WINDOW_NAME}
    tmux send-keys -t ${TMX_SESSION}:${TMX_WINDOW_NAME} "${TMX_START_CMD}; tmux wait-for -S 0" ENTER
    tmux wait-for 0
  )
}

function tmux_start() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    tmux_new $ctx
    tmux_check_window_name || return $?
    tmux_check_start_cmd || return $?
    tmux select-window -t ${TMX_SESSION}:${TMX_WINDOW_NAME} || tmux new-window -t ${TMX_SESSION} -n ${TMX_WINDOW_NAME}
    tmux send-keys -t ${TMX_SESSION}:${TMX_WINDOW_NAME} "${TMX_START_CMD}" ENTER
  )
}

function tmux_stop() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    tmux_check_session || return $?
    tmux_check_window_name || return $?
    tmux has-session -t ${TMX_SESSION} && tmux kill-window -t ${TMX_SESSION}:${TMX_WINDOW_NAME} || echo "Window ${TMX_SESSION}:${TMX_WINDOW_NAME} was not opened."
  )
}

function tmux_kill() {
  tmux kill-server || true
}

function tmux_connect() {
  (
    dt_ctx $@; exit_on_err $0 $? || return $?
    tmux a -t ${TMX_SESSION}
  )
}

function tmux_sessions() {
  tmux ls
}
