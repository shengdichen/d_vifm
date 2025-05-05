#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"
cd "${SCRIPT_PATH}" || exit 3

__build() {
    local _out="./.config/vifm/scripts/main" _src="./src"
    if ! clang \
        -Wall -pedantic \
        -O2 \
        -o "${_out}" \
        -- "${_src}/filequeue.c" "${_src}/handler.c" "${_src}/util.c" "${_src}/main.c"; then
        printf "\n\nbuild> failed, exiting\n"
        exit 3
    fi
}

__stow() {
    local _config_vifm="${HOME}/.config/vifm"
    mkdir -p "${_config_vifm}"
    mkdir -p "${_config_vifm}/conf"

    stow -R --target "${HOME}" "linux"
    (
        cd "./common" && stow -R --target "${_config_vifm}" "vifm"
    )
}
# __build
__stow
