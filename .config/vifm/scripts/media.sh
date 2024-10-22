#!/usr/bin/env bash

LOCAL_SCRIPT="${HOME}/.local/script"
LOCAL_LIB="${HOME}/.local/lib"

. "${LOCAL_LIB}/util.sh"

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

    if __check -- "${1}"; then
        ffprobe -loglevel quiet -show_format -pretty "${1}" 2>&1
    fi
}

__handle() {
    if [ "${1}" = "--" ]; then shift; fi

    local _targets=()
    for _target in "${@}"; do
        if [ ! -d "${_target}" ]; then
            if __check -- "${_target}"; then
                _targets+=("${_target}")
            fi
            continue
        fi

        while read -r _f; do
            if __check -- "${_f}"; then
                _targets+=("${_f}")
            fi
        done < <(find "${_target}" -mindepth 1 -type f | sort -n)
    done

    local _mpv="${LOCAL_SCRIPT}/mpv.sh"
    case "$(__fzf_opts "auto" "record" "socket")" in
        "auto")
            "${_mpv}" -- "${_targets[@]}"
            ;;
        "record")
            "${_mpv}" record -- "${_targets[@]}"
            ;;
        "socket")
            "${_mpv}" socket -- "${_targets[@]}"
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
