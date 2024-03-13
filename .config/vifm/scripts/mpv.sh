#!/usr/bin/env dash

__fzf() {
    fzf --reverse --height=37%
}

__to_socket() {
    socat - ~/.local/state/mpv/throw.sok
}

__play_throw() {
    if [ "${1}" = "--" ]; then shift; fi

    local _mode
    _mode="$(for _mode in "replace" "append"; do
        printf "%s\n" "${_mode}"
    done | __fzf)"

    for _target in "${@}"; do
        if [ "${_mode}" = "append" ]; then
            printf "loadfile \"%s\" append-play\n" "${_target}"
        else
            printf "loadfile \"%s\" replace\n" "${_target}"
        fi | __to_socket
    done
    printf "set pause no\n" | __to_socket
}
__play_throw "${@}"
