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
    local _interactive="" _choice="copy"
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--interactive")
                _interactive="${2}"
                shift 2
                ;;
            "--mode")
                _choice="${2}"
                shift 2
                ;;
            "--")
                shift && break
                ;;
            *)
                exit 3
                ;;
        esac
    done

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

__handle_new() {
    local _path
    _path="$(realpath .)"
    case "${_path}" in
        *"/.${PASS_DIR}/"*) ;;
        *)
            printf "pass/new> not in [pass]-dir, cd there first\n"
            return 1
            ;;
    esac

    local _target
    _target="$(printf "%s\n" "${_path}" | sed "s/^.*\/\.${PASS_DIR}\/\(.*\)$/\1\/_new/")"
    pass generate "${_target}" 1>/dev/null 2>&1
    __handle_common --mode edit -- "${_target}"
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
    "new")
        shift
        __handle_new "${@}"
        ;;
    *)
        __handle "${@}"
        ;;
esac
