#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

__check() {
    if [ "${1}" = "--" ]; then shift; fi

    for _p in "${@}"; do
        case "${_p}" in
            *".md5" | \
                *".sha"* | \
                *".asc" | *".sig") ;;
            *) return 1 ;;
        esac
    done
}

__calc() {
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
        _mode="$(
            __fzf_opts \
                "sha/256" "md5" "sha/512" \
                "sha/1" "sha/224" "sha/384" "sha/512224" "sha512256"
        )"
    fi

    case "${_mode}" in
        "md5")
            md5sum -- "${@}"
            ;;
        "sha/"*)
            shasum \
                --algorithm "$(printf "%s" "${_mode}" | cut -d "/" -f "2")" \
                -- "${@}"
            ;;
    esac
}

__verify() {
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
        _mode="$(__fzf_opts "md5" "sha" "gpg")"
    fi

    case "${_mode}" in
        "md5")
            md5sum --check -- "${@}"
            ;;
        "sha")
            shasum --check -- "${@}"
            ;;
        "gpg")
            gpg --verify -- "${@}"
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
    if ! __check -- "${1}"; then return 1; fi

    local _choice="nvim"
    if [ "${_interactive}" ]; then
        _choice="$(__select_opt "nvim" "check")"
    fi
    if [ "${_choice}" = "nvim" ]; then
        __nvim -- "${1}"
        return
    fi

    if case "${1}" in
        *".md5")
            __verify --mode md5 -- "${1}"
            ;;
        *".sha"*)
            __verify --mode sha -- "${1}"
            ;;
        *".asc" | *".sig")
            __verify --mode gpg -- "${1}"
            ;;
    esac then
        __separator
        printf "hash/check> success "
        read -r _
    fi
    __separator
    printf "hash/check> FAIL "
    read -r _
}

case "${1}" in
    *)
        __calc "${@}"
        ;;
esac
