function __mpv() {
    nohup mpv "${@}" 1>/dev/null 2>&1 &

}

function main() {
    case "${1}" in
        "mpv" )
            __mpv "${@:2}"
            ;;
    esac

    unset -f __mpv
}
main "${@}"
unset -f main
