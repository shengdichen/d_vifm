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

function __tree() {
    # -a := show hidden files
    # -l := follow links
    tree -a -l "${@}" | format_standard ""
}

function __info_media() {
    case "${1}" in
        "ffmpeg" )
            ffprobe -loglevel quiet -show_format -pretty "${2}" 2>&1 | format_standard ""
            ;;
        "image" )
            identify "${@:2}"
            ;;
    esac | format_standard ""
}

function main() {
    case "${1}" in
        "nvim" )
            __nvim "${@:2}"
            ;;
        "preview" )
            __preview "${@:2}"
            ;;
        "tree" )
            __tree "${@:2}"
            ;;
        "mpv" | "imv" | "zathura" | "pdfarranger" | "xournalpp" | "lyx" | "libreoffice" | "sqlitebrowser" )
            spawn_proc "${1}" "${@:2}"
            ;;
        "info_ffmpeg" )
            __info_media "ffmpeg" "${2}"
            ;;
        "info_image" )
            __info_media "image" "${@:2}"
            ;;
    esac

    unset -f __nvim __preview __tree __info_media
}
main "${@}"
unset -f main
