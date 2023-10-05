function next_pane_is_zsh() {
    local cmd_next_pane
    cmd_next_pane=$(tmux display-message -p -t ":.+1" -F "#{pane_current_command}")
    [[ "${cmd_next_pane}" == "zsh" ]]
}

function cd_next_pane() {
    local target="${1}"
    # C-U := clear existing input
    tmux send-keys -t ":.+1" \
        "C-U" "cd ${target}" "Enter"

    tmux select-pane -Z -t ":.+1"
}

function create_split() {
    if (( ${#} == 0 )); then
        tmux split-window -v
    elif (( ${#} == 1 )); then
        tmux split-window "${1}"
    else
        tmux split-window -v -t "${1}" "${2}"
    fi
}

function split_shell() {
    if next_pane_is_zsh; then
        cd_next_pane "${1}"
    else
        create_split
    fi
}

function split_vifm() {
    create_split "vifm"
}

function split_file() {
    local idx_target="1"
    if next_pane_is_zsh; then
        idx_target="2"
    fi

    create_split ":.${idx_target}" "nvim -O ${*}"
}

function main() {
    case "${1}" in
        "shell" )
            split_shell "${2}"
            ;;
        "vifm" )
            split_vifm
            ;;
        "file" )
            split_file "${@:2}"
    esac

    unset -f next_pane_is_zsh cd_next_pane create_split split_shell split_vifm split_file
}
main "${@}"
unset -f main
