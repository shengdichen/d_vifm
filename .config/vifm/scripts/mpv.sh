#!/usr/bin/env dash

__fzf() {
    fzf --reverse --height=37%
}

__to_socket() {
    printf "%s\n" "${1}" | socat - ~/.local/state/mpv/throw.sok
}

__play_throw() {
    if [ "${1}" = "--" ]; then shift; fi

    local _mode
    _mode="$(for _mode in "replace" "append"; do
        printf "%s\n" "${_mode}"
    done | __fzf)"

    local _counter=0
    find "${@}" -type f -print |
        sort |
        while IFS="" read -r _file; do
            if [ "${_mode}" = "replace" ] && [ "${_counter}" -eq 0 ]; then
                _counter="$((_counter + 1))"
                __to_socket "loadfile \"${_file}\" replace"
            else
                __to_socket "loadfile \"${_file}\" append"
            fi
        done
    __to_socket "set pause no"
}

__play_adhoc() {
    if [ "${1}" = "--" ]; then shift; fi
    find "${@}" -type f -print |
        sort |
        xargs -d "\n" -- \
            mpv \
            --no-save-position-on-quit \
            --no-resume-playback \
            --
}

__main() {
    local _mode="adhoc"
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--mode")
                _mode="${2}"
                shift && shift
                ;;
            "--")
                shift && break
                ;;
            *)
                exit 3
                ;;
        esac
    done

    case "${_mode}" in
        "adhoc")
            __play_adhoc -- "${@}"
            ;;
        "throw")
            __play_throw -- "${@}"
            ;;
        *)
            exit 3
            ;;
    esac
}
__main "${@}"
