#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

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

__handle() {
    local _mime _need_recalc_mime
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--mime")
                _mime="${2}"
                shift 2
                ;;
            "--")
                shift && break
                ;;
        esac
    done
    if [ ! "${_mime}" ]; then
        _need_recalc_mime="yes"
    fi

    for _file in "${@}"; do
        if [ "${_need_recalc_mime}" ]; then
            _mime="$(file --brief --mime-type --dereference -- "${_file}")"
        fi
        printf "archive> %s [type: %s]\n" "${_file}" "${_mime}"

        case "${_mime}" in
            "application/x-tar")
                case "$(__fzf_opts "nvim" "unmake" "peak" "nvim/ro")" in
                    "nvim")
                        __nvim -- "${_file}"
                        ;;
                    "unmake")
                        tar -xvf "${_file}"
                        ;;
                    "peak")
                        tar -tvf "${_file}" | __nvim --mode ro
                        ;;
                    "nvim/ro")
                        __nvim --mode ro -- "${_file}"
                        ;;
                esac
                ;;

            "application/x-bzip2")
                case "${_file}" in
                    *".tbz" | *".tbz2" | *".tar.bz" | *".tar.bz2")
                        case "$(__fzf_opts "nvim" "unmake" "peak" "nvim/ro")" in
                            "nvim")
                                __nvim -- "${_file}"
                                ;;
                            "unmake")
                                tar --bzip2 -xvf "${_file}"
                                ;;
                            "peak")
                                tar --bzip2 -tvf "${_file}" | __nvim --mode ro
                                ;;
                            "nvim/ro")
                                __nvim --mode ro -- "${_file}"
                                ;;
                        esac
                        ;;
                    *) # *".bz" | *".bz2")
                        case "$(__fzf_opts "nvim" "unmake" "nvim/ro")" in
                            "nvim")
                                __nvim -- "${_file}"
                                ;;
                            "unmake")
                                bzip2 --keep -d "${_file}"
                                ;;
                            "nvim/ro")
                                __nvim --mode ro -- "${_file}"
                                ;;
                        esac
                        ;;
                esac
                ;;

            "application/gzip")
                case "${_file}" in
                    *".tar.gz" | *.t[ga]z | *".tar.Z")
                        case "$(__fzf_opts "nvim" "unmake" "peak" "nvim/ro")" in
                            "nvim")
                                __nvim -- "${_file}"
                                ;;
                            "unmake")
                                tar --gzip -xvf "${_file}"
                                ;;
                            "peak")
                                tar --gzip -tvf "${_file}" | __nvim --mode ro
                                ;;
                            "nvim/ro")
                                __nvim --mode ro -- "${_file}"
                                ;;
                        esac
                        ;;
                    *) # *".z" | *".gz")
                        local _opt
                        case "$(realpath "${_file}")" in
                            "/usr/share/man/"*)
                                _opt="$(__fzf_opts "nvim/man" "nvim/ro")"
                                ;;
                            "/usr/share/info/"*)
                                _opt="$(__fzf_opts "nvim/info" "nvim/ro")"
                                ;;
                            *)
                                _opt="$(__fzf_opts "nvim" "unmake" "nvim/ro" "nvim/man" "nvim/info")"
                                ;;
                        esac

                        case "${_opt}" in
                            "nvim/man")
                                man -l -- "${_file}"
                                ;;
                            "nvim/info")
                                info -f "${_file}" | __nvim --mode ro
                                ;;
                            "nvim")
                                __nvim -- "${_file}"
                                ;;
                            "unmake")
                                gzip --keep -d "${_file}"
                                ;;
                            "nvim/ro")
                                __nvim --mode ro -- "${_file}"
                                ;;
                        esac
                        ;;
                esac
                ;;

            "application/x-xz")
                case "${_file}" in
                    *.tar.[xl]z | *.t[xl]z)
                        case "$(__fzf_opts "nvim" "unmake" "peak" "nvim/ro")" in
                            "nvim")
                                __nvim -- "${_file}"
                                ;;
                            "unmake")
                                tar --xz -xvf "${_file}"
                                ;;
                            "peak")
                                tar --xz -tvf "${_file}" | __nvim --mode ro
                                ;;
                            "nvim/ro")
                                __nvim --mode ro -- "${_file}"
                                ;;
                        esac
                        ;;
                    *) # *.[xl]z | *".lzma")
                        case "$(__fzf_opts "nvim" "unmake" "nvim/ro")" in
                            "nvim")
                                __nvim -- "${_file}"
                                ;;
                            "unmake")
                                xz --keep -d "${_file}"
                                ;;
                            "nvim/ro")
                                __nvim --mode ro -- "${_file}"
                                ;;
                        esac
                        ;;
                esac
                ;;

            "application/zstd")
                case "${_file}" in
                    *".tar.zst")
                        case "$(__fzf_opts "nvim" "unmake" "peak" "nvim/ro")" in
                            "nvim")
                                __nvim -- "${_file}"
                                ;;
                            "unmake")
                                tar --zstd -xvf "${_file}"
                                ;;
                            "peak")
                                tar --zstd -tvf "${_file}" | __nvim --mode ro
                                ;;
                            "nvim/ro")
                                __nvim --mode ro -- "${_file}"
                                ;;
                        esac
                        ;;
                    *) # *".zst")
                        case "$(__fzf_opts "nvim" "unmake" "nvim/ro")" in
                            "nvim")
                                __nvim -- "${_file}"
                                ;;
                            "unmake")
                                zstd --keep -d "${_file}"
                                ;;
                            "nvim/ro")
                                __nvim --mode ro -- "${_file}"
                                ;;
                        esac
                        ;;
                esac
                ;;

            "application/zip" | "application/java-archive")
                # *".zip" | *".apk" | *".apkg" | *[ejw]ar)
                case "$(__fzf_opts "nvim" "peak" "unmake" "nvim/ro")" in
                    "nvim")
                        __nvim -- "${_file}"
                        ;;
                    "peak")
                        unzip -l "${1}" | __nvim --mode ro
                        ;;
                    "unmake")
                        unzip "${_file}"
                        ;;
                    "nvim/ro")
                        __nvim --mode ro -- "${_file}"
                        ;;
                esac
                ;;

            "application/x-7z-compressed" | "application/x-iso9660-image") # *".7z" | *".iso")
                case "$(__fzf_opts "peak" "unmake")" in
                    "peak")
                        7z l "${_file}" | __nvim --mode ro
                        ;;
                    "unmake")
                        7z x "${_file}"
                        ;;
                esac
                ;;

            "application/x-rar" | "application/vnd.rar") # *".rar")
                case "$(__fzf_opts "peak" "unmake")" in
                    "peak")
                        unrar l "${1}" | __nvim --mode ro
                        ;;
                    "unmake")
                        unrar x "${_file}"
                        ;;
                esac
                ;;
        esac
        printf "\n"
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
            case "$(__fzf_opts "tar+${_format}" "${_format}")" in
                "tar+"*)
                    _mode="singletar"
                    ;;
                *)
                    _mode="single"
                    ;;
            esac
        else
            case "$(
                __fzf_opts \
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
    _format="$(__fzf_opts "tar" "bzip2" "gzip" "xz" "zstd" "zip" "7z")"
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
    "make")
        shift
        __make "${@}"
        ;;
    *)
        __handle "${@}"
        ;;
esac
