#!/usr/bin/env dash

if [ "${1}" = "--" ]; then shift; fi
for _file in "${@}"; do
    case "${_file}" in
        *"tmux")
            tmux source-file "${_file}"
            ;;
        *"py")
            python "${_file}"
            ;;
        *"sh")
            if [ -x "${_file}" ]; then
                ./"${_file}"
            else
                ${SHELL} "${_file}"
            fi
            ;;
        *)
            printf "direct> unrecognized filetype [%s], skipping" "${_file}"
            ;;
    esac
done
