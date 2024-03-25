#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/general.sh"

__check() {
    if [ "${1}" = "--" ]; then shift; fi
    for _p in "${@}"; do
        case "${_p}" in
            *".tar" | \
                *".tbz" | *".tbz2" | *".tar.bz" | *".tar.bz2" | \
                *".bz" | *".bz2" | \
                *".tar.gz" | *t[ga]z | *".tar.Z" | \
                *".z" | *".gz" | \
                *.tar.[xl]z | *.t[xl]z | \
                *.[xl]z | *".lzma" | \
                *".tar.zst" | \
                *".zst" | \
                *".7z" | *".iso" | \
                *".zip" | *".apk" | *".apkg" | *[ejw]ar | \
                *".rar") ;;
            *) return 1 ;;
        esac
    done
}

__info() {
    if [ "${1}" = "--" ]; then shift; fi

    for _file in "${@}"; do
        case "${_file}" in
            *".tar")
                tar -tvf "${_file}"
                ;;

            *".tbz" | *".tbz2" | *".tar.bz" | *".tar.bz2")
                tar --bzip2 -tvf "${_file}"
                ;;
            *".bz" | *".bz2")
                bzip2 --keep -d --stdout "${_file}"
                ;;

            *".tar.gz" | *t[ga]z | *".tar.Z")
                tar --gzip -tvf "${_file}"
                ;;
            *".z" | *".gz")
                gzip --keep -d --stdout "${_file}"
                ;;

            *.tar.[xl]z | *.t[xl]z)
                tar --xz -tvf "${_file}"
                ;;
            *.[xl]z | *".lzma")
                xz --keep -d --stdout "${_file}"
                ;;

            *".tar.zst")
                tar --zstd -tvf "${_file}"
                ;;
            *".zst")
                zstd --keep -d --stdout "${_file}"
                ;;

            *".7z" | *".iso")
                7z l "${_file}" | tail -n +19
                ;;
            *".zip" | *".apk" | *".apkg" | *[ejw]ar)
                unzip -l "${1}" | tail -n +2
                ;;
            *".rar")
                unrar l "${1}" | tail -n +5 | head -n -1
                ;;
            *)
                return 1
                ;;
        esac
    done
}

__unmake() {
    if [ "${1}" = "--" ]; then shift; fi

    for _file in "${@}"; do
        printf "archive/unmake> [%s]\n" "${_file}"
        case "${_file}" in
            *".tar")
                tar -xvf "${_file}"
                ;;

            *".tbz" | *".tbz2" | *".tar.bz" | *".tar.bz2")
                tar --bzip2 -xvf "${_file}"
                ;;
            *".bz" | *".bz2")
                bzip2 --keep -d "${_file}"
                ;;

            *".tar.gz" | *.t[ga]z | *".tar.Z")
                tar --gzip -xvf "${_file}"
                ;;
            *".z" | *".gz")
                gzip --keep -d "${_file}"
                ;;

            *.tar.[xl]z | *.t[xl]z)
                tar --xz -xvf "${_file}"
                ;;
            *.[xl]z | *".lzma")
                xz --keep -d "${_file}"
                ;;

            *".tar.zst")
                tar --zstd -xvf "${_file}"
                ;;
            *".zst")
                zstd --keep -d "${_file}"
                ;;

            *".7z" | *".iso")
                7z x "${_file}"
                ;;
            *".zip" | *".apk" | *".apkg" | *[ejw]ar)
                unzip "${_file}"
                ;;
            *".rar")
                unrar x "${_file}"
                ;;
            *)
                return 1
                ;;
        esac
        printf "\n"
    done
}

__handle() {
    local _interactive=""
    if [ "${1}" = "--interactive" ]; then
        _interactive="${2}"
        shift 2
    fi
    if [ "${1}" = "--" ]; then shift; fi
    if ! __check -- "${@}"; then return 1; fi

    local _choice
    for _file in "${@}"; do
        case "${_file}" in
            *".tar" | \
                *".tbz" | *".tbz2" | *".tar.bz" | *".tar.bz2" | \
                *".bz" | *".bz2" | \
                *".tar.gz" | *t[ga]z | *".tar.Z" | \
                *".z" | *".gz" | \
                *.tar.[xl]z | *.t[xl]z | \
                *.[xl]z | *".lzma" | \
                *".tar.zst" | \
                *".zst" | \
                *".zip" | *".apk" | *".apkg" | *[ejw]ar)
                _choice="nvim"
                if [ "${_interactive}" ]; then
                    _choice="$(__select_opt "nvim" "info" "unmake")"
                fi
                ;;
            *".7z" | *".iso" | \
                *".rar")
                _choice="info"
                if [ "${_interactive}" ]; then
                    _choice="$(__select_opt "info" "unmake")"
                fi
                ;;
        esac
        case "${_choice}" in
            "unmake")
                __unmake -- "${_file}"
                ;;
            "nvim")
                __nvim -- "${_file}"
                ;;
            "info")
                __info -- "${_file}" | __nvim --mode ro
                ;;
        esac
    done
}

__make() {
    if [ "${1}" = "--" ]; then shift; fi

    local _format
    _format="$(
        for _format in "tar" "bzip2" "gzip" "xz" "zstd" "7z" "zip"; do
            printf "%s\n" "${_format}"
        done | __fzf
    )"

    if [ "${_format}" = "tar" ]; then
        tar -cv -f "_new.tar" -- "${@}"
        return
    fi

    local _input
    printf "archive/make> [c]ombine-into-one (default), [s]eparate-for-each? "
    read -r _input
    if [ "${_input}" != "s" ]; then
        case "${_format}" in
            "bzip2")
                tar "--${_format}" -cv -f "_new.tar.bz2" -- "${@}"
                ;;
            "gzip")
                tar "--${_format}" -cv -f "_new.tar.gz" -- "${@}"
                ;;
            "xz")
                tar "--${_format}" -cv -f "_new.tar.${_format}" -- "${@}"
                ;;
            "zstd")
                tar "--${_format}" -cv -f "_new.tar.zst" -- "${@}"
                ;;
            "7z")
                7z a "_new.7z" -- "${@}"
                ;;
            "zip")
                zip -r "_new.zip" -- "${@}"
                ;;
        esac
    else
        case "${_format}" in
            "bzip2" | "gzip" | "xz" | "zstd")
                "${_format}" --keep "${@}"
                ;;
            "7z")
                for _target in "${@}"; do
                    7z a "${_target}.7z" -- "${_target}"
                done
                ;;
            "zip")
                for _target in "${@}"; do
                    zip -r "${_target}.zip" -- "${_target}"
                done
                ;;
        esac
    fi
}

case "${1}" in
    "check")
        shift
        __check "${@}"
        ;;
    "info")
        shift
        __info "${@}"
        ;;
    "unmake")
        shift
        __unmake "${@}"
        ;;
    "make")
        shift
        __make "${@}"
        ;;
    *)
        __handle "${@}"
        ;;
esac
