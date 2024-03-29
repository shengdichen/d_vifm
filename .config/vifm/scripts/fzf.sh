#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/general.sh"

__fzf() {
    fzf --reverse --height=73% 2>/dev/tty
}

__to_line() {
    # a separator unlikely found in filenames
    local _separator=":::"
    local _res _line _file
    if _res="$(
        rg \
            --hidden \
            --color never --no-heading --with-filename --line-number \
            --field-match-separator "${_separator}" \
            ".*" -- . |
            cut -c 3- | # hide leading "./"
            __fzf
    )"; then
        _file="$(printf "%s" "${_res}" | awk -F "${_separator}" "{print \$1}")"
        _line="$(printf "%s" "${_res}" | awk -F "${_separator}" "{print \$2}")"
        nvim +"${_line}" -- "${_file}"
    fi
}

__to_path() {
    local _type=""
    case "${1}" in
        "dir")
            shift
            _type="d"
            ;;
        "file")
            shift
            _type="f"
            ;;
    esac

    if [ ! "${_type}" ]; then
        find . -printf "%P\n" | __fzf
    else
        find . -type "${_type}" -printf "%P\n" | __fzf
    fi
}

case "${1}" in
    "dir")
        shift
        __to_path dir
        ;;
    "file")
        shift
        __to_path file
        ;;
    *)
        __to_line
        ;;
esac
