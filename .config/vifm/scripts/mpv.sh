#!/usr/bin/env dash

__send() {
    local _append=""
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--append")
                _append="yes"
                shift
                ;;
            "--")
                shift && break
                ;;
            *)
                exit 3
                ;;
        esac
    done

    for _target in "${@}"; do
        if [ "${_append}" ]; then
            printf "loadfile \"%s\" append-play\n" "${_target}"
        else
            printf "loadfile \"%s\" replace\n" "${_target}"
        fi | socat - ~/.local/state/mpv/throw.sok
    done
}
__send "${@}"
