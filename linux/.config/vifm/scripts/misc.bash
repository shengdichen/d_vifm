#!/usr/bin/env bash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/util.sh"

__spectrogram() {
    if [ "${1}" = "--" ]; then shift; fi

    local _suffix="png" _out _outs=()
    for _target in "${@}"; do
        case "${_target}" in
            *".flac") ;;
            *".m4a")
                local _target_new="${_target%.m4a}.flac"
                ffmpeg \
                    -i "${_target}" \
                    -codec:a flac \
                    "${_target_new}"
                _target="${_target_new}"
                ;;
            *)
                printf "spectrogram> unrecognized filetype, skipping... [%s]\n" "${_target}"
                continue
                ;;
        esac

        _out="${_target}.${_suffix}"
        sox "${_target}" -n spectrogram -o "${_out}"
        _outs+=("${_out}")
    done
    __nohup imv "${_outs[@]}"
}

__tidal() {
    if [ "${1}" = "--" ]; then shift; fi

    __get() {
        tidal-dl -l "${1}"
    }

    local _target
    if [ "${#}" -gt 0 ]; then
        for _target in "${@}"; do
            __get "${_target}"
        done
    else
        printf "tidal> target: "
        read -r _target
        if "${_target}"; then
            __get "${_target}"
        fi
    fi
}

__main() {
    local _choice
    _choice="$(__select_opt "spectrogram" "tidal")"
    case "${_choice}" in
        "spectrogram")
            __spectrogram "${@}"
            ;;
        "tidal")
            __tidal "${@}"
            ;;
        *) ;;
    esac
}
__main "${@}"
