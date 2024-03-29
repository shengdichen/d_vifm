#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/general.sh"

__check_aud() {
    if [ "${1}" = "--" ]; then shift; fi
    for _p in "${@}"; do
        case "${_p}" in
            *".flac" | *".wav" | *".ape" | \
                *".mp3" | *.m4[ab] | \
                *".wma" | *".ac3" | *.og[agx] | *".spx" | *".opus") ;;
            *) return 1 ;;
        esac
    done
}

__check_vid() {
    if [ "${1}" = "--" ]; then shift; fi
    for _p in "${@}"; do
        case "${_p}" in
            *".mkv" | \
                *".avi" | *".mp4" | *".webm" | *".ts" | *.m[4o]v | \
                *".mpg" | *".mpeg" | *".vob" | *.fl[icv] | \
                *".wmv" | *".dat" | *".3gp" | *".ogv" | *".m2v" | *".mts" | \
                *.r[am] | *".qt" | *".divx" | *.as[fx]) ;;
            *) return 1 ;;
        esac
    done
}

__check() {
    if [ "${1}" = "--" ]; then shift; fi

    for _p in "${@}"; do
        if ! (
            __check_vid -- "${_p}" || __check_aud -- "${_p}"
        ); then
            return 1
        fi
    done
}

__info() {
    if [ "${1}" = "--" ]; then shift; fi

    if ! __check -- "${1}"; then return 1; fi
    ffprobe -loglevel quiet -show_format -pretty "${1}" 2>&1
}

__handle() {
    local _interactive=""
    if [ "${1}" = "--interactive" ]; then
        _interactive="${2}"
        shift && shift
    fi
    if [ "${1}" = "--" ]; then shift; fi
    if ! __check -- "${@}"; then return 1; fi

    local _choice="mpv"
    if [ "${_interactive}" ]; then
        if [ "${#}" -gt 1 ]; then
            _choice="$(
                __select_opt "mpv" "mpv/record" "mpv/throw"
            )"
        else
            _choice="$(
                __select_opt "mpv" "mpv/record" "mpv/throw"
            )"
        fi
    fi
    case "${_choice}" in
        "mpv")
            "${SCRIPT_PATH}/mpv.sh" -- "${@}"
            ;;
        "mpv/record")
            "${SCRIPT_PATH}/mpv.sh" --mode record -- "${@}"
            ;;
        "mpv/throw")
            "${SCRIPT_PATH}/mpv.sh" --mode throw -- "${@}"
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
