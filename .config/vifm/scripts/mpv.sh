#!/usr/bin/env dash

__send() {
    for _target in "${@}"; do
        printf "loadfile \"%s\" append-play\n" "${_target}" | socat - ~/.local/state/mpv/throw.sok
    done
}
__send "${@}"
