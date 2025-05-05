#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

__check() {
    if [ "${1}" = "--" ]; then shift; fi

    for _f in "${@}"; do
        case "${_f}" in
            *".pdf") ;;
            *) return 1 ;;
        esac
    done
}

__handle() {
    local _check="" _interactive=""
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--check")
                _check="yes"
                shift
                ;;
            "--interactive")
                _interactive="yes"
                shift
                ;;
            "--")
                shift && break
                ;;
        esac
    done

    if [ "${_check}" ] && ! __check -- "${@}"; then
        return 1
    fi

    local _choice="zathura"
    if [ "${_interactive}" ]; then
        if [ "${#}" -gt 1 ]; then
            _choice="$(
                __fzf_opts "zathura" "xournal++" "pdfarranger/multi" "pdfarranger/foreach" "pdftotext"
            )"
        else
            _choice="$(
                __fzf_opts "zathura" "xournal++" "pdfarranger" "pdftotext"
            )"
        fi
    fi

    case "${_choice}" in
        "zathura")
            for _f in "${@}"; do
                __nohup zathura -- "${_f}"
            done
            ;;
        "xournal++")
            for _f in "${@}"; do
                __nohup xournalpp -- "${_f}"
            done
            ;;
        "pdfarranger/multi")
            __nohup pdfarranger -- "${@}"
            ;;
        "pdfarranger/foreach" | "pdfarranger")
            for _f in "${@}"; do
                __nohup pdfarranger -- "${_f}"
            done
            ;;
        "pdftotext")
            for _f in "${@}"; do
                printf "// [%s]\n" "${_f}"
                pdftotext -nopgbrk "${_f}" -
                printf "\n\n"
            done | __nvim --mode ro
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
