#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

SCRIPT_PATH="${HOME}/.config/vifm/scripts"
LOCAL_SCRIPT="${HOME}/.local/script"

__info() {
    if [ "${1}" = "--" ]; then shift; fi

    local _counter=0
    for _f in "${@}"; do
        if [ "${_counter}" -eq 0 ]; then
            _counter="$((_counter + 1))"
        else
            printf "\n----------\n\n"
        fi

        printf "// "
        if [ ! -d "${_f}" ]; then
            file --brief --dereference --mime -- "${_f}"
        else
            file --brief --dereference -- "${_f}"
        fi
        stat -- "${_f}" | __line_number
    done
}

__preview() {
    if [ "${1}" = "--" ]; then shift; fi

    local _counter=0 _info
    for _f in "${@}"; do
        if [ "${_counter}" -eq 0 ]; then
            _counter="$((_counter + 1))"
        else
            printf "\n----------\n\n"
        fi

        printf "// "
        if [ ! -d "${_f}" ]; then
            file --brief --dereference --mime -- "${_f}"
            stat "${_f}" | __line_number

            printf "<<<<<<<<<<\n"

            _info=""
            for _script in \
                "${SCRIPT_PATH}/media.sh" \
                "${LOCAL_SCRIPT}/image.sh" \
                "${SCRIPT_PATH}/misc.sh" \
                "${LOCAL_SCRIPT}/archive.sh"; do
                if _info="$("${_script}" info -- "${_f}")"; then
                    break
                fi
            done
            if [ "${_info}" ]; then
                printf "%s" "${_info}" | __line_number
            else
                printf "## NO EXTRA INFO ##\n"
            fi

            printf ">>>>>>>>>>\n"
        else
            file --brief --dereference -- "${_f}"
            stat "${_f}" | __line_number

            printf "<<<<<<<<<<\n"
            if [ -n "$(find -L "${_f}" -mindepth 1)" ]; then
                tree -a -l -L 1 --filelimit 197 "${_f}" | __line_number
            else
                printf "## EMPTY DIR ##\n"
            fi
            printf "<<<<<<<<<<\n"
        fi
    done
}

case "${1}" in
    "preview")
        shift
        __preview "${@}"
        ;;
    "info")
        shift
        __info "${@}"
        ;;
esac
