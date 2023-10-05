function __nvim() {
    local flag

    if [[ "${1}" == "open" ]]; then
        flag="O"
    elif [[ "${1}" == "diff" ]]; then
        flag="d"
    fi
    echo $flag

    nvim "-${flag}" "${@:2}"
}

function main() {
    case "${1}" in
        "nvim" )
            __nvim "${@:2}"
            ;;
    esac

    unset -f __nvim
}
main "${@}"
unset -f main
