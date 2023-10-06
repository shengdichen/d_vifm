source "util.sh"

function __mpv() {
    nohup mpv "${@}" 1>/dev/null 2>&1 &

}

function __info_ffmpeg() {
    ffprobe -loglevel quiet -show_format -pretty "${1}" 2>&1 | format_standard
}

function main() {
    case "${1}" in
        "mpv" )
            __mpv "${@:2}"
            ;;
        "info" )
            __info_ffmpeg "${2}"
    esac

    unset -f __mpv __info_ffmpeg
}
main "${@}"
unset -f main
