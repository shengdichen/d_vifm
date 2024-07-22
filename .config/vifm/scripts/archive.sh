#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

. "${SCRIPT_PATH}/util.sh"

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
                *".z" | \
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
            *".gz")
                local _path
                _path="$(realpath "${_file}")"
                case "${_path}" in
                    "/usr/share/man/"*)
                        _choice="nvim"
                        if [ "${_interactive}" ]; then
                            _choice="$(__select_opt "nvim (man)" "raw" "info" "unmake")"
                        fi
                        if [ "${_choice}" = "nvim" ]; then
                            man -l -- "${_file}"
                            continue
                        fi
                        ;;
                    "/usr/share/info/"*)
                        _choice="nvim"
                        if [ "${_interactive}" ]; then
                            _choice="$(__select_opt "nvim (info)" "raw" "info" "unmake")"
                        fi
                        if [ "${_choice}" = "nvim" ]; then
                            info -f "${_file}" | __nvim --mode ro
                            continue
                        fi
                        ;;
                    *)
                        _choice="nvim"
                        if [ "${_interactive}" ]; then
                            _choice="$(__select_opt "nvim" "info" "unmake")"
                        fi
                        ;;
                esac

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
            "nvim" | "raw")
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

    local _has_multi=""
    if [ ${#} -gt 1 ]; then
        _has_multi="yes"
    fi

    __make_tar() {
        local _mode="c"
        if [ "${_has_multi}" ]; then
            printf "archive/make> [c]ombine-into-one (multi), [s]eparate-for-each? "
            read -r _mode
        fi
        if [ "${_mode}" != "s" ]; then # multi
            tar -cv -f "_new.tar" -- "${@}"
        else
            for _f in "${@}"; do
                tar -cv -f "${_f}.tar" -- "${_f}"
            done
        fi
    }

    __make_zip_like() {
        local _format="${1}"
        shift

        local _mode="c"
        if [ "${_has_multi}" ]; then
            printf "archive/make> [c]ombine-into-one (multi), [s]eparate-for-each? "
            read -r _mode
        fi

        if [ "${_mode}" != "s" ]; then # multi
            case "${_format}" in
                "7z")
                    7z a "_new.7z" -- "${@}"
                    ;;
                "zip")
                    zip -r "_new.zip" -- "${@}"
                    ;;
            esac
        else
            case "${_format}" in
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

    __make_unix() {
        local _format="${1}"
        shift

        local _mode
        if [ ! "${_has_multi}" ]; then
            case "$(__select_opt "tar+${_format}" "${_format}")" in
                "tar+"*)
                    _mode="singletar"
                    ;;
                *)
                    _mode="single"
                    ;;
            esac
        else
            case "$(
                __select_opt \
                    "multi/tar+${_format}" \
                    "foreach/tar+${_format}" \
                    "foreach/${_format}"
            )" in
                "multi/"*)
                    _mode="multi"
                    ;;
                "foreach/tar+"*)
                    _mode="singletar"
                    ;;
                *)
                    _mode="single"
                    ;;
            esac
        fi

        case "${_mode}" in
            "multi")
                case "${_format}" in
                    "bzip2")
                        tar "--${_format}" -cv -f "_new.tar.bz2" -- "${@}"
                        ;;
                    "gzip")
                        tar "--${_format}" -cv -f "_new.tar.gz" -- "${@}"
                        ;;
                    "xz")
                        tar "--${_format}" -cv -f "_new.tar.xz" -- "${@}"
                        ;;
                    "zstd")
                        tar "--${_format}" -cv -f "_new.tar.zst" -- "${@}"
                        ;;
                esac
                ;;
            "singletar")
                case "${_format}" in
                    "bzip2")
                        for _f in "${@}"; do
                            tar "--${_format}" -cv -f "${_f}.tar.bz2" -- "${_f}"
                        done
                        ;;
                    "gzip")
                        for _f in "${@}"; do
                            tar "--${_format}" -cv -f "${_f}.tar.gz" -- "${_f}"
                        done
                        ;;
                    "xz")
                        for _f in "${@}"; do
                            tar "--${_format}" -cv -f "${_f}.tar.xz" -- "${_f}"
                        done
                        ;;
                    "zstd")
                        for _f in "${@}"; do
                            tar "--${_format}" -cv -f "${_f}.tar.zst" -- "${_f}"
                        done
                        ;;
                esac
                ;;
            "single")
                "${_format}" --keep -- "${@}"
                ;;
        esac
    }

    local _format
    _format="$(__select_opt "tar" "bzip2" "gzip" "xz" "zstd" "zip" "7z")"
    case "${_format}" in
        "tar")
            __make_tar "${@}"
            ;;
        "zip" | "7z")
            __make_zip_like "${_format}" "${@}"
            ;;
        "bzip2" | "gzip" | "xz" | "zstd")
            __make_unix "${_format}" "${@}"
            ;;
    esac
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
