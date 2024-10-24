#!/usr/bin/env bash

# SCRIPT_PATH="$(realpath "$(dirname "${0}")")"
SCRIPT_PATH="${HOME}/.config/vifm/scripts"

LOCAL_SCRIPT="${HOME}/.local/script"
. "${HOME}/.local/lib/util.sh"
. "${HOME}/.local/lib/filter.sh"

__handle() {
    local _interactive=""
    if [ "${1}" = "--interactive" ]; then
        _interactive="yes"
        shift
    fi
    if [ "${1}" = "--" ]; then shift; fi

    local _nvims=() _mpvs=() _imvs=() _pdfs=() _others=()

    local _mime=""
    for _f in "${@}"; do
        if __check_media --mode name -- "${_f}"; then
            _mpvs+=("${_f}")
            continue
        fi
        if "${LOCAL_SCRIPT}/image.sh" check "${_f}"; then
            _imvs+=("${_f}")
            continue
        fi
        if "${LOCAL_SCRIPT}/pass.sh" check -- "${_f}"; then
            "${LOCAL_SCRIPT}/pass.sh" -- "${_f}"
            continue
        fi

        case "${_f}" in
            *".xopp")
                __nohup xournalpp "${_f}"
                continue
                ;;
            *".lyx")
                __nohup lyx "${_f}"
                continue
                ;;

            *".sh" | *".zsh" | *".bash")
                if ! [ "${_interactive}" ]; then
                    _nvims+=("${_f}")
                    continue
                fi
                case "$(__fzf_opts "execute (shell)" "nvim")" in
                    "nvim")
                        _nvims+=("${_f}")
                        ;;
                    "execute")
                        "${SCRIPT_PATH}/dev.sh" shell -- "${_f}"
                        ;;
                esac
                continue
                ;;
            *".py")
                if ! [ "${_interactive}" ]; then
                    _nvims+=("${_f}")
                    continue
                fi
                case "$(__fzf_opts "nvim" "execute (python)")" in
                    "nvim")
                        _nvims+=("${_f}")
                        ;;
                    "execute")
                        "${SCRIPT_PATH}/dev.sh" python -- "${_f}"
                        ;;
                esac
                continue
                ;;
            *".tmux")
                if ! [ "${_interactive}" ]; then
                    _nvims+=("${_f}")
                    continue
                fi
                case "$(__fzf_opts "nvim" "execute (tmux)")" in
                    "nvim")
                        _nvims+=("${_f}")
                        ;;
                    "execute")
                        "${SCRIPT_PATH}/dev.sh" tmux -- "${_f}"
                        ;;
                esac
                continue
                ;;
        esac

        # NOTE:
        #   use as last resort only since the mime-check is slow
        _mime="$(file --brief --mime-type --dereference -- "${_f}")"
        case "${_mime}" in
            "text/"* | \
                "inode/x-empty" | \
                "application/javascript" | \
                "application/json" | \
                "application/x-subrip" | \
                "application/x-wine-extension-ini" | \
                "application/x-ndjson" | \
                "application/x-pem-file" | \
                "message/rfc822")
                _nvims+=("${_f}")
                ;;

            "audio/"* | "video/"*)
                _mpvs+=("${_f}")
                ;;
            "image/"*)
                _imvs+=("${_f}")
                ;;
            "application/pdf")
                _pdfs+=("${_f}")
                ;;

            "application/x-tar" | \
                \
                "application/x-bzip2" | \
                "application/gzip" | \
                "application/x-xz" | \
                "application/zstd" | \
                \
                "application/zip" | \
                "application/vnd.android.package-archive" | \
                "application/java-archive" | \
                \
                "application/x-7z-compressed" | \
                "application/x-iso9660-image" | \
                \
                "application/x-rar")
                "${LOCAL_SCRIPT}/archive.sh" --mime "${_mime}" -- "${_f}"
                ;;

            "application/x-bittorrent")
                transmission-show "${_f}" | __nvim --mode ro
                ;;

            "application/x-pie-executable" | \
                "application/octet-stream" | \
                "application/x-qemu-disk")
                printf "run> skipping '%s' [%s] " "${_f}" "${_mime}"
                read -r _
                printf "\n"
                continue
                ;;
            *)
                _others+=("${_f}")
                ;;
        esac
    done

    if ! [ ${#_mpvs[@]} -eq 0 ]; then
        if ! [ "${_interactive}" ]; then
            "${LOCAL_SCRIPT}/mpv.sh" --no-filter -- "${_mpvs[@]}"
        else
            case "$(__fzf_opts "auto" "record" "socket")" in
                "auto")
                    "${LOCAL_SCRIPT}/mpv.sh" --no-filter -- "${_mpvs[@]}"
                    ;;
                "record")
                    "${LOCAL_SCRIPT}/mpv.sh" record --no-filter -- "${_mpvs[@]}"
                    ;;
                "socket")
                    "${LOCAL_SCRIPT}/mpv.sh" socket --no-filter -- "${_mpvs[@]}"
                    ;;
            esac
        fi
    fi

    if ! [ ${#_imvs[@]} -eq 0 ]; then
        if ! [ "${_interactive}" ]; then
            "${LOCAL_SCRIPT}/image.sh" -- "${_imvs[@]}"
        else
            "${LOCAL_SCRIPT}/image.sh" --interactive -- "${_imvs[@]}"
        fi
    fi

    if ! [ ${#_pdfs[@]} -eq 0 ]; then
        if ! [ "${_interactive}" ]; then
            "${LOCAL_SCRIPT}/pdf.sh" -- "${_pdfs[@]}"
        else
            "${LOCAL_SCRIPT}/pdf.sh" --interactive -- "${_pdfs[@]}"
        fi
    fi

    for _f in "${_others[@]}"; do
        __nohup xdg-open "${_f}"
    done

    if ! [ ${#_nvims[@]} -eq 0 ]; then
        __nvim -- "${_nvims[@]}"
    fi
}

__handle "${@}"
