#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/util.sh"

__check() {
    if [ "${1}" = "--" ]; then shift; fi
    for _p in "${@}"; do
        case "${_p}" in
            *".tmux" | *".py" | *".sh") ;;
            *) return 1 ;;
        esac
    done
}

__handle_python() {
    __has_venv() {
        poetry env info --quiet
    }

    __in_venv() {
        __has_venv && (
            printf "%s\n" "${PATH}" | grep --quiet "${HOME}/.cache/pypoetry/virtualenvs/"
        )
    }

    if [ "${1}" = "--" ]; then shift; fi

    if ! __has_venv; then
        python -- "${1}"
    else
        if ! __in_venv; then
            poetry run -- python -- "${1}"
        else
            python -- "${1}"
        fi
    fi
}

__handle() {
    local _interactive=""
    if [ "${1}" = "--interactive" ]; then
        _interactive="${2}"
        shift 2
    fi
    if [ "${1}" = "--" ]; then shift; fi
    if ! __check -- "${@}"; then return 1; fi

    local _choice="nvim"
    if [ "${_interactive}" ]; then
        _choice="$(__select_opt "exe" "nvim")"
    fi
    case "${_choice}" in
        "exe")
            for _file in "${@}"; do
                case "${_file}" in
                    *".tmux")
                        tmux source-file "${_file}"
                        ;;
                    *".py")
                        __handle_python -- "${_file}"
                        ;;
                    *".sh")
                        if [ -x "${_file}" ]; then
                            ./"${_file}"
                        else
                            ${SHELL} "${_file}"
                        fi
                        ;;
                    *)
                        printf "direct> unrecognized filetype [%s], skipping" "${_file}"
                        ;;
                esac
            done
            ;;
        *) return 1 ;;
    esac
}

case "${1}" in
    "check")
        shift
        __check "${@}"
        ;;
    *)
        __handle "${@}"
        ;;
esac
