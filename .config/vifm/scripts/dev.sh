#!/usr/bin/env dash

__check() {
    if [ "${1}" = "--" ]; then shift; fi
    case "${1}" in
        *".tmux" | *".py" | *".sh"* | ".zsh" | *".bash") ;;
        *) return 1 ;;
    esac
}

__handle_shell() {
    if [ "${1}" = "--" ]; then shift; fi

    if [ -x "${1}" ]; then
        ./"${1}"
    else
        ${SHELL} "${1}"
    fi
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
        return
    fi
    if ! __in_venv; then
        poetry run -- python -- "${1}"
        return
    fi
    python -- "${1}"
}

__handle_tmux() {
    if [ "${1}" = "--" ]; then shift; fi
    tmux source-file "${1}"
}

__main() {
    if [ "${#}" -eq 0 ]; then
        return
    fi

    case "${1}" in
        "check")
            shift
            __check "${@}"
            ;;
        "shell")
            shift
            __handle_shell "${@}"
            ;;
        "python")
            shift
            __handle_python "${@}"
            ;;
        "tmux")
            shift
            __handle_tmux "${@}"
            ;;
    esac
}
__main "${@}"
