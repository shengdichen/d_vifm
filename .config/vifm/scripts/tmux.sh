function next_pane_is_zsh() {
    local cmd_next_pane
    cmd_next_pane=$(tmux display-message -p -t ":.+1" -F "#{pane_current_command}")
    [[ "${cmd_next_pane}" == "zsh" ]]
}

function cd_next_pane() {
    local target="${1}"
    tmux send-keys -t ":.+1" \
        "cd " '"' "${target}" '"' "Enter"

    tmux select-pane -Z -t ":.+1"
}

function create_split() {
    tmux split-window -v -t ":."
}

function main() {
    if next_pane_is_zsh; then
        cd_next_pane "${1}"
    else
        create_split
    fi

    unset -f next_pane_is_zsh cd_next_pane create_split
}
main "${@}"
unset -f main
