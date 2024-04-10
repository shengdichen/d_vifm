#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/util.sh"

__check() {
    if [ "${1}" = "--" ]; then shift; fi

    for _p in "${@}"; do
        case "${_p}" in
            *".pdf") ;;
            *) return 1 ;;
        esac
    done
}

__handle() {
    local _interactive=""
    if [ "${1}" = "--interactive" ]; then
        _interactive="${2}"
        shift 2
    fi
    if [ "${1}" = "--" ]; then shift; fi
    if ! __check -- "${@}"; then return 1; fi

    local _choice="zathura"
    if [ "${_interactive}" ]; then
        if [ "${#}" -gt 1 ]; then
            _choice="$(
                __select_opt "pdfarranger/multi" "pdfarranger/foreach" "xournal++" "pdftotext" "zathura"
            )"
        else
            _choice="$(
                __select_opt "pdfarranger" "xournal++" "pdftotext" "zathura"
            )"
        fi
    fi

    case "${_choice}" in
        "pdfarranger/multi")
            __nohup pdfarranger -- "${@}"
            ;;
        "pdfarranger/foreach" | "pdfarranger")
            for _p in "${@}"; do
                __nohup pdfarranger -- "${_p}"
            done
            ;;
        "xournal++")
            for _p in "${@}"; do
                __nohup xournalpp -- "${_p}"
            done
            ;;
        "pdftotext")
            for _p in "${@}"; do
                printf "// [%s]\n" "${_p}"
                pdftotext -nopgbrk "${_p}" -
                printf "\n\n"
            done | __nvim --mode ro
            ;;
        "zathura")
            __nohup zathura -- "${@}"
            ;;
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
