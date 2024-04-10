#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/util.sh"

__check() {
    if [ "${1}" = "--" ]; then shift; fi

    for _p in "${@}"; do
        case "${_p}" in
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
    local _interactive=""
    if [ "${1}" = "--interactive" ]; then
        _interactive="${2}"
        shift 2
    fi
    if [ "${1}" = "--" ]; then shift; fi
    if ! __check -- "${@}"; then return 1; fi

    local _choice="imv/multi"
    if [ "${_interactive}" ]; then
        if [ "${#}" -gt 1 ]; then
            _choice="$(__select_opt "imv/multi" "imv/foreach")"
        fi
    fi
    case "${_choice}" in
        "imv/multi")
            __nohup imv -- "${@}"
            ;;
        "imv/foreach")
            for _p in "${@}"; do
                __nohup imv -- "${@}"
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
