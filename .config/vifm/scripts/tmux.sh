#!/usr/bin/env dash

__next_pane_is_zsh() {
    local _cmd_next_pane
    _cmd_next_pane=$(tmux display-message -p -t ":.+1" -F "#{pane_current_command}")
    [ "${_cmd_next_pane}" = "zsh" ]
}

__create_split() {
    if [ ${#} -eq 0 ]; then
        tmux split-window -v
    elif [ ${#} -eq 1 ]; then
        tmux split-window -v "${1}"
    else
        tmux split-window -v -t "${1}" "${2}"
    fi
}

__split_shell() {
    __cd_next_pane() {
        # C-U := clear existing input
        tmux send-keys -t ":.+1" \
            "C-U" "cd ${1}" "Enter"

        tmux select-pane -Z -t ":.+1"
    }

    __respawn_if_dead() {
        if [ "$(tmux display-message -p -t "${1}" -F "#{pane_dead}")" -eq 1 ]; then
            tmux respawn-pane
        fi
    }

    if __next_pane_is_zsh; then
        __cd_next_pane "${1}"
        __respawn_if_dead ":."
    else
        __create_split
    fi
}

__split_file() {
    local _pane_id="1"
    if __next_pane_is_zsh; then
        _pane_id="2"
    fi

    local _flag
    if [ "${1}" = "open" ]; then
        _flag="O"
    elif [ "${1}" = "diff" ]; then
        _flag="d"
    fi

    __create_split ":.${_pane_id}" "nvim -${_flag} ${2}"
}

case "${1}" in
    "shell")
        shift
        __split_shell "${1}"
        ;;
    "file")
        shift
        __split_file "${@}"
        ;;
    "vifm")
        __create_split "vifm"
        ;;
    *)
        echo "Huh, what about tmux?"
        ;;
esac
