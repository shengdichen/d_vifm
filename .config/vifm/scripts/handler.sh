source "util.sh"

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

function __preview() {
    cat "${@}" | format_standard ""
}

function __mpv() {
    spawn_proc "mpv" "${@}"
}

function __info_ffmpeg() {
    ffprobe -loglevel quiet -show_format -pretty "${1}" 2>&1 | format_standard ""
}

function main() {
    case "${1}" in
        "nvim" )
            __nvim "${@:2}"
            ;;
        "preview" )
            __preview "${@:2}"
            ;;
        "mpv" )
            __mpv "${@:2}"
            ;;
        "info_ffmpeg" )
            __info_ffmpeg "${2}"
    esac

    unset -f __nvim __preview __mpv __info_ffmpeg
}
main "${@}"
unset -f main
