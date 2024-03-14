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

    local _counter=0
    find "${@}" -type f -print |
        sort |
        while IFS="" read -r _file; do
            if [ "${_mode}" = "replace" ] && [ "${_counter}" -eq 0 ]; then
                _counter="$((_counter + 1))"
                printf "loadfile \"%s\" replace\n" "${_file}" | __to_socket
            else
                printf "loadfile \"%s\" append\n" "${_file}" | __to_socket
            fi
        done
    printf "set pause no\n" | __to_socket
}
__play_throw "${@}"
