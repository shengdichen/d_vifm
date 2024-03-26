#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/general.sh"

PASS_DIR="password-store" # intentionally without leading dot
CLIPBOARD_TIME=7          # in second(s)

__check() {
    if [ "${1}" = "--" ]; then shift; fi

    for _p in "${@}"; do
        case "${_p}" in
            *"/.${PASS_DIR}/"*".gpg") ;;
            *) return 1 ;;
        esac
    done
}

__handle_otp() {
    if [ "${1}" = "--" ]; then shift; fi
    PASSWORD_STORE_CLIP_TIME="${CLIPBOARD_TIME}" \
        pass otp code -c "${1}" >/dev/null
}

__handle_common() {
    local _interactive=""
    if [ "${1}" = "--interactive" ]; then
        _interactive="${2}"
        shift 2
    fi
    if [ "${1}" = "--" ]; then shift; fi

    local _choice="copy"
    if [ "${_interactive}" ]; then
        _choice="$(__select_opt "copy" "edit" "view")"
    fi
    case "${_choice}" in
        "copy")
            PASSWORD_STORE_CLIP_TIME="${CLIPBOARD_TIME}" \
                pass -c "${1}" >/dev/null
            ;;
        "edit")
            pass edit "${1}" 2>/dev/null
            if [ "${?}" -eq 1 ]; then
                return 0 # pass returns 1 if no changes made
            fi
            ;;
        "view")
            pass show "${1}" | __nvim --mode ro
            ;;
    esac
}

__handle() {
    local _interactive=""
    if [ "${1}" = "--interactive" ]; then
        _interactive="${2}"
        shift 2
    fi
    if [ "${1}" = "--" ]; then shift; fi

    local _path
    _path="$(realpath "${1}")"
    if ! __check -- "${_path}"; then return 1; fi

    local _target
    _target=$(
        printf "%s" "${_path}" | sed "s/^.*\.${PASS_DIR}\/\(.*\)\.gpg$/\1/"
    )
    case "${_target}" in
        *".mfa")
            __handle_otp -- "${_target}"
            ;;
        *)
            __handle_common --interactive "${_interactive}" -- "${_target}"
            ;;
    esac
}

case "${1}" in
    *)
        __handle "${@}"
        ;;
esac
