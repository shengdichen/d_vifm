#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/general.sh"

SOCKET_DIR="${HOME}/.local/state/mpv"

__fzf() {
    fzf --reverse --height=37%
}

__to_socket() {
    printf "%s\n" "${1}" | socat - "${SOCKET_DIR}/${2}.sok"
}

__find_files() {
    find "${@}" -type f -print | sort
}

__play_socket() {
    local _socket="throw"
    if [ "${1}" = "-s" ]; then
        _socket="${2}"
        shift && shift
    fi
    if [ "${1}" = "--" ]; then shift; fi

    __mpv_socket() {
        __find_files "${@}" | xargs -d "\n" -- \
            nohup mpv \
            --input-ipc-server="${SOCKET_DIR}/${_socket}.sok" \
            --
    }
    if ! pgrep -u "$(whoami)" -a |
        cut -d " " -f 2- |
        grep -q "^mpv.*--input-ipc-server=.*/\.local/state/mpv/${_socket}\.sok"; then
        __mpv_socket "${@}" >/dev/null 2>&1 &
        return
    fi

    local _mode
    _mode="$(for _mode in "replace" "append"; do
        printf "%s\n" "${_mode}"
    done | __fzf)"

    local _counter=0
    __find_files "${@}" |
        while IFS="" read -r _file; do
            if [ "${_mode}" = "replace" ] && [ "${_counter}" -eq 0 ]; then
                _counter="$((_counter + 1))"
                __to_socket "loadfile \"${_file}\" replace" "${_socket}"
            else
                __to_socket "loadfile \"${_file}\" append" "${_socket}"
            fi
        done
    __to_socket "set pause no" "${_socket}"
}

__play_new() {
    local _record=""
    if [ "${1}" = "--record" ]; then
        _record="yes"
        shift
    fi
    if [ "${1}" = "--" ]; then shift; fi

    if [ "${_record}" ]; then
        __find_files "${@}" | xargs -d "\n" -- \
            nohup mpv \
            --save-position-on-quit \
            --resume-playback \
            --
    else
        __find_files "${@}" | xargs -d "\n" -- \
            nohup mpv \
            --no-save-position-on-quit \
            --no-resume-playback \
            --
    fi
}

__main() {
    local _mode="adhoc"
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--mode")
                _mode="${2}"
                if [ "${_mode}" = "ask" ]; then
                    _mode="$(__select_opt "adhoc (default)" "record" "throw")"
                fi
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
            __play_new -- "${@}" >/dev/null 2>&1 &
            ;;
        "record")
            __play_new --record -- "${@}" >/dev/null 2>&1 &
            ;;
        "throw")
            __play_socket -- "${@}"
            ;;
        *)
            exit 3
            ;;
    esac
}
__main "${@}"
