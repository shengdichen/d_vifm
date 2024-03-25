#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/general.sh"

__info() {
    if [ "${1}" = "--" ]; then shift; fi

    case "${1}" in
        *".torrent")
            transmission-show -D -T -- "${1}"
            ;;
        *) return 1 ;;
    esac
}

__handle() {
    local _interactive=""
    if [ "${1}" = "--interactive" ]; then
        _interactive="${2}"
        shift 2
    fi
    if [ "${1}" = "--" ]; then shift; fi

    local _choice
    case "${1}" in
        *".xopp")
            __nohup xournalpp -- "${1}"
            ;;
        *".lyx")
            __nohup lyx "${1}"
            ;;
        *.od[tp] | *".xls" | *".xlsx" | *".ppt" | *".pptx")
            __nohup libreoffice "${1}"
            ;;
        *".doc")
            _choice="libreoffice"
            if [ "${_interactive}" ]; then
                _choice="$(__select_opt "libreoffice" "nvim (catdoc)")"
            fi
            case "${_choice}" in
                "libreoffice")
                    __nohup libreoffice "${1}"
                    ;;
                "nvim")
                    catdoc "${1}" | __nvim --mode ro
                    ;;
            esac
            ;;
        *".docx")
            _choice="libreoffice"
            if [ "${_interactive}" ]; then
                _choice="$(__select_opt "libreoffice" "nvim (docx2txt)")"
            fi
            case "${_choice}" in
                "libreoffice")
                    __nohup libreoffice "${1}"
                    ;;
                "nvim")
                    docx2txt.pl "${1}" | __nvim --mode ro
                    ;;
            esac
            ;;
        *".db" | *".db3" | *".sqlite" | *".sqlite3")
            __nohup sqlitebrowser "${1}"
            ;;
        *".torrent")
            _choice="nvim"
            if [ "${_interactive}" ]; then
                _choice="$(__select_opt "nvim (transmission)" "deluge")"
            fi
            case "${_choice}" in
                "deluge")
                    __nohup deluge-gtk -- "${1}"
                    ;;
                "nvim")
                    transmission-show "${1}" | __nvim --mode ro
                    ;;
            esac
            ;;
        *) return 1 ;;
    esac
}

case "${1}" in
    "info")
        shift
        __info "${@}"
        ;;
    *)
        __handle "${@}"
        ;;
esac
