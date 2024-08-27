#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

PASS_DIR="password-store" # intentionally without leading dot
CLIPBOARD_TIME=7          # in second(s)
EXTENSION_MFA="mfa"

__check() {
    if [ "${1}" = "--" ]; then shift; fi

    for _p in "${@}"; do
        case "$(realpath "${_p}")" in
            *"/.${PASS_DIR}/"*".gpg") ;;
            *) return 1 ;;
        esac
    done
}

__path_to_pass() {
    sed "s/^.*\/\.${PASS_DIR}\/\(.*\)\.gpg$/\1/"
}

__select_pass() {
    find -L "${HOME}/.${PASS_DIR}/" -type f | grep "\.gpg$" | __fzf | __path_to_pass
}

__handle_common() {
    local _mode
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--mode")
                _mode="${2}"
                shift 2
                ;;
            "--")
                shift && break
                ;;
        esac
    done

    if [ ! "${_mode}" ]; then
        _mode="$(__fzf_opts "copy" "edit" "view")"
    fi
    case "${_mode}" in
        "copy")
            PASSWORD_STORE_CLIP_TIME="${CLIPBOARD_TIME}" \
                pass -c "${1}" >/dev/null
            ;;
        "edit")
            pass edit "${1}" 2>/dev/null
            if [ "${?}" -eq 1 ]; then
                true # pass returns 1 if no changes made
            fi
            ;;
        "view")
            pass show "${1}" | __nvim --mode ro
            ;;
    esac
}

__handle_otp() {
    local _mode
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--mode")
                _mode="${2}"
                shift 2
                ;;
            "--")
                shift && break
                ;;
        esac
    done
    if [ ! "${_mode}" ]; then
        _mode="$(__fzf_opts "copy" "view" "edit")"
    fi

    case "${_mode}" in
        "copy")
            PASSWORD_STORE_CLIP_TIME="${CLIPBOARD_TIME}" \
                pass otp code -c "${1}" >/dev/null
            ;;
        "view")
            printf "pass/otp> %s [%s] " \
                "$(PASSWORD_STORE_CLIP_TIME="${CLIPBOARD_TIME}" \
                    pass otp code "${1}")" \
                "${1}"
            read -r _
            ;;
        "edit")
            __handle_common --mode edit -- "${1}"
            ;;
    esac
}

__handle() {
    local _check=""
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--check")
                _check="yes"
                shift
                ;;
            "--")
                shift && break
                ;;
        esac
    done

    local _pass
    if [ "${#}" -eq 0 ]; then
        _pass="$(__select_pass)"
    else
        local _path
        _path="$(realpath "${1}")"
        if [ "${_check}" ]; then
            if ! __check -- "${_path}"; then return 1; fi
        fi
        _pass="$(printf "%s" "${_path}" | __path_to_pass)"
    fi

    case "${_pass}" in
        *".${EXTENSION_MFA}")
            __handle_otp -- "${_pass}"
            ;;
        *)
            __handle_common -- "${_pass}"
            ;;
    esac
}

__make_new() {
    local _path
    _path="$(realpath .)"
    case "${_path}" in
        *"/.${PASS_DIR}/"*) ;;
        *)
            printf "pass/new> not in [pass]-dir, cd there first\n"
            return 1
            ;;
    esac
    if [ "${1}" = "--" ]; then shift; fi

    local _target
    _target="$(printf "%s\n" "${_path}" | sed "s/^.*\/\.${PASS_DIR}\/\(.*\)$/\1\/_new/")"
    if [ "${#}" -gt 0 ]; then
        if "${SCRIPT_PATH}/image.sh" check -- "${1}"; then
            _choice="$(__select_opt "mfa" "common")"
            if [ "${_choice}" = "mfa" ]; then
                zbarimg -q --raw "${1}" | pass otp insert "${_target}.${EXTENSION_MFA}"
                return
            fi
        fi
    fi
    pass generate "${_target}" 1>/dev/null 2>&1
    __handle_common --mode edit -- "${_target}"
}

case "${1}" in
    "check")
        shift
        __check "${@}"
        ;;
    "new")
        shift
        __make_new "${@}"
        ;;
    *)
        __handle "${@}"
        ;;
esac
