#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/util.sh"

__check() {
    if [ "${1}" = "--" ]; then shift; fi

    for _p in "${@}"; do
        case "${_p}" in
            *".md5" | \
                *".sha1" | *".sha256" | *".sha512" | \
                *".asc" | *".sig") ;;
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
    if ! __check -- "${1}"; then return 1; fi

    local _choice="nvim"
    if [ "${_interactive}" ]; then
        _choice="$(__select_opt "nvim" "check")"
    fi
    if [ "${_choice}" = "nvim" ]; then
        __nvim -- "${1}"
    else
        case "${1}" in
            *".md5")
                if [ "${_choice}" = "check" ]; then
                    md5sum -c -- "${1}"
                fi
                ;;
            *".sha1")
                if [ "${_choice}" = "check" ]; then
                    sha1sum -c -- "${1}"
                fi
                ;;
            *".sha256")
                if [ "${_choice}" = "check" ]; then
                    sha256sum -c -- "${1}"
                fi
                ;;
            *".sha512")
                if [ "${_choice}" = "check" ]; then
                    sha512sum -c -- "${1}"
                fi
                ;;
            *".asc" | *".sig")
                if [ "${_choice}" = "check" ]; then
                    gpg --verify -- "${1}"
                fi
                ;;
        esac
        if [ "${?}" -eq 0 ]; then
            printf "\nhash/check> success "
            read -r _
        else
            printf "\nhash/check> FAIL "
            read -r _
        fi
    fi
}

case "${1}" in
    *)
        __handle "${@}"
        ;;
esac
