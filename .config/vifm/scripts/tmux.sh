#!/usr/bin/env dash

next_pane_is_zsh() {
    local cmd_next_pane
    cmd_next_pane=$(tmux display-message -p -t ":.+1" -F "#{pane_current_command}")
    [ "${cmd_next_pane}" = "zsh" ]
}

respawn_if_dead() {
    if [ "$(tmux display-message -p -t "${1}" -F "#{pane_dead}")" -eq 1 ]; then
        tmux respawn-pane
    fi
}

cd_next_pane() {
    # C-U := clear existing input
    tmux send-keys -t ":.+1" \
        "C-U" "cd ${1}" "Enter"

    tmux select-pane -Z -t ":.+1"
}

create_split() {
    if [ ${#} -eq 0 ]; then
        tmux split-window -v
    elif [ ${#} -eq 1 ]; then
        tmux split-window -v "${1}"
    else
        tmux split-window -v -t "${1}" "${2}"
    fi
}

split_shell() {
    if next_pane_is_zsh; then
        cd_next_pane "${1}"
        respawn_if_dead ":."
    else
        create_split
    fi
}

split_vifm() {
    create_split "vifm"
}

split_file() {
    local idx_target="1"
    if next_pane_is_zsh; then
        idx_target="2"
    fi

    local flag
    if [ "${1}" = "open" ]; then
        flag="O"
    elif [ "${1}" = "diff" ]; then
        flag="d"
    fi

    create_split ":.${idx_target}" "nvim -${flag} ${2}"
}

case "${1}" in
    "shell")
        shift
        split_shell "${1}"
        ;;
    "vifm")
        split_vifm
        ;;
    "file")
        shift
        split_file "${@}"
        ;;
    *)
        echo "Huh, what about tmux?"
        ;;
esac
