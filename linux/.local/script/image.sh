#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

__check() {
    if [ "${1}" = "--" ]; then shift; fi

    for _f in "${@}"; do
        case "${_f}" in
            *".png" | *".svg" | \
                *".jpg" | *".jpeg" | *".bmp" | *".webp" | *".gif" | *".xpm" | \
                *".heif" | *".heifs" | *".heic" | *".heics" | avc[is] | *".avif") ;;
            *) return 1 ;;
        esac
    done
}

__info() {
    if [ "${1}" = "--" ]; then shift; fi
    if ! __check -- "${1}"; then return 1; fi
    identify -- "${1}"
}

__handle() {
    local _check="" _interactive=""
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--check")
                _check="yes"
                shift
                ;;
            "--interactive")
                _interactive="yes"
                shift
                ;;
            "--")
                shift && break
                ;;
        esac
    done

    if [ "${_check}" ] && ! __check -- "${@}"; then
        return 1
    fi

    if [ ! "${_interactive}" ] || [ ${#} -eq 1 ]; then
        __nohup imv -- "${@}"
        return
    fi

    case "$(__fzf_opts "imv/multi" "imv/foreach")" in
        "imv/multi")
            __nohup imv -- "${@}"
            ;;
        "imv/foreach")
            for _f in "${@}"; do
                __nohup imv -- "${_f}"
            done
            ;;
    esac
}

case "${1}" in
    "check")
        shift
        __check "${@}"
        ;;
    "info")
        shift
        __info "${@}"
        ;;
    *)
        __handle "${@}"
        ;;
esac
