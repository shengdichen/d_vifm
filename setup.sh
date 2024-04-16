#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"
cd "${SCRIPT_PATH}" || exit 3

__build() {
    local _out="./.config/vifm/scripts/main" _src="./src"
    if ! clang \
        -O2 -Wall \
        -o "${_out}" \
        -- "${_src}/filequeue.c" "${_src}/handler.c" "${_src}/util.c" "${_src}/main.c"; then
        printf "\n\nbuild> failed, exiting\n"
        exit 3
    fi
}

__stow() {
    (
        cd "../" && stow -R \
            --target="${HOME}/" \
            --ignore="\.git.*" \
            --ignore="src" \
            --ignore="setup.sh" \
            "$(basename "${SCRIPT_PATH}")"
    )
}
__build
__stow
