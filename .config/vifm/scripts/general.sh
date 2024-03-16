#!/usr/bin/env dash

__fzf() {
    fzf --reverse --height=37%
}

__nvim() {
    if [ "${1}" = "--mode" ]; then
        case "${2}" in
            "diff")
                shift && shift
                if [ "${#}" -gt 0 ]; then
                    nvim -d "${@}"
                else
                    nvim -d
                fi
                ;;
            "ro")
                shift && shift
                if [ "${#}" -gt 0 ]; then
                    nvim -R -c "set nomodifiable" "${@}"
                else
                    nvim -R -c "set nomodifiable"
                fi
                ;;
            "*")
                exit 3
                ;;
        esac
    else
        if [ "${#}" -gt 0 ]; then
            nvim -O "${@}"
        else
            nvim -O
        fi
    fi
}
