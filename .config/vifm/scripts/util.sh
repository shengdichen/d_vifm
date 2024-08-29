#!/usr/bin/env dash

__find_files() {
    find "${@}" -type f -print | sort
}

__fzf() {
    fzf --reverse --height=37%
}

__select_opt() {
    local _choice
    if ! _choice="$(
        for _opt in "${@}"; do printf "%s\n" "${_opt}"; done | __fzf
    )"; then
        _choice="${1}"
    fi
    printf "%s\n" "${_choice}" | cut -d " " -f "1"
}

__line_number() {
    nl -b a -w 2 -n "rz" -s "  "
}

__tmp_file() {
    echo "${HOME}/.local/share/vifm/tmp_$(date --iso-8601=seconds)"
}

__array_append() {
    local _arr="${1}"
    shift
    if [ "${1}" = "--" ]; then shift; fi
    for _e in "${@}"; do
        if [ ! "${_arr}" ]; then
            _arr="${_e}"
        else
            _arr="${_arr}\n${_e}"
        fi
    done
    printf "%s" "${_arr}"
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
            "tmp")
                shift && shift
                if [ "${1}" = "--" ]; then shift; fi
                nvim \
                    -R \
                    -c "set nomodifiable" \
                    -c "autocmd VimLeavePre * !rm ${1}" \
                    -- "${1}"
                # HACK:
                #   avoid nvim's buggy exit-status 134, which in turns hangs vifm
                # REF:
                #   https://github.com/neovim/neovim/issues/21856
                #   https://github.com/vifm/vifm/issues/527
                if [ "${?}" -eq 134 ]; then
                    true
                else
                    return
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
            "array")
                shift && shift
                if [ "${1}" = "--" ]; then shift; fi
                if [ "${1}" ]; then
                    echo "${1}" | xargs -o -d "\n" nvim -O --
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

__nohup() {
    nohup "${@}" >/dev/null 2>&1 &
}
