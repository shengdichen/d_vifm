#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/util.sh"

__info() {
    local _preview=""
    if [ "${1}" = "preview" ]; then
        shift
        _preview="yes"
    fi
    if [ "${1}" = "--" ]; then shift; fi

    local _counter=0 _info
    for _p in "${@}"; do
        if [ "${_counter}" -eq 0 ]; then
            _counter="$((_counter + 1))"
        else
            printf "\n----------\n\n"
        fi

        if [ ! -d "${_p}" ]; then
            printf "// "
            file --brief --mime --dereference -- "${_p}"
            stat "${_p}" | __line_number

            if [ ! "${_preview}" ]; then
                printf "<<<<<<<<<<\n"

                _info=""
                for _script in "media" "image" "misc" "archive"; do
                    if _info="$("${SCRIPT_PATH}/${_script}.sh" info -- "${_p}")"; then
                        break
                    fi
                done
                if [ "${_info}" ]; then
                    printf "%s" "${_info}" | __line_number
                else
                    printf "## NO EXTRA INFO ##\n"
                fi

                printf ">>>>>>>>>>\n"
            fi
        else
            printf "// "
            file --brief -- "${_p}"
            stat "${_p}" | __line_number

            if [ ! "${_preview}" ]; then
                if [ -n "$(find "${_p}" -mindepth 1)" ]; then
                    tree -a -l -L 1 --filelimit 197 "${_p}" | __line_number
                else
                    printf "// %s\n" "${_p}"
                    printf "## EMPTY DIR ##\n"
                fi
            fi
        fi
    done
}

__generic() {
    if [ "${1}" = "--" ]; then shift; fi

    case "$(
        __select_opt \
            "info" \
            "mpv" \
            "archive (make)" \
            "nvim"
    )" in
        "info")
            __info -- "${@}" | __nvim --mode ro
            ;;
        "mpv")
            "${SCRIPT_PATH}/mpv.sh" --mode ask -- "${@}"
            ;;
        "archive")
            "${SCRIPT_PATH}/archive.sh" make -- "${@}"
            ;;
        "nvim")
            __nvim -- "${@}"
            ;;
    esac
}

__foreach() {
    local _interactive=""
    if [ "${1}" = "--interactive" ]; then
        _interactive="${2}"
        shift 2
    fi
    if [ "${1}" = "--" ]; then shift; fi

    local _to_nvim _files_to_nvim=""
    for _p in "${@}"; do
        _to_nvim="yes"
        for _script in "media" "image" "direct" "pdf" "misc" "archive" "encrypt" "pass"; do
            if "${SCRIPT_PATH}/${_script}.sh" --interactive "${_interactive}" -- "${_p}"; then
                _to_nvim=""
                break
            fi
        done

        if [ "${_to_nvim}" ]; then
            _files_to_nvim="$(__array_append "${_files_to_nvim}" "${_p}")"
        fi
    done
    __nvim --mode array -- "${_files_to_nvim}"
}

__multi() {
    local _interactive=""
    if [ "${1}" = "--interactive" ]; then
        _interactive="${2}"
        shift 2
    fi
    if [ "${1}" = "--" ]; then shift; fi

    for _script in "media" "image" "direct" "pdf"; do
        if
            "${SCRIPT_PATH}/${_script}.sh" --interactive "${_interactive}" -- "${@}"
        then
            return
        fi
    done
    __foreach --interactive "${_interactive}" -- "${@}"
}

case "${1}" in
    "--preview")
        shift
        __info preview "${@}"
        ;;
    "--generic")
        shift
        __generic "${@}"
        ;;
    "--interactive")
        shift
        __multi --interactive "yes" "${@}"
        ;;
    *)
        __multi "${@}"
        ;;
esac
