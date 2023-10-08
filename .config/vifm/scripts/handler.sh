source "util.sh"

function __nvim() {
    if [[ "${1}" == "open" ]]; then
        flag="O"
    elif [[ "${1}" == "diff" ]]; then
        flag="d"
    fi

    nvim "-${flag}" "${@:2}"
}

function __preview() {
    function __file() {
        if [[ -s "${1}" ]]; then
            format_standard <"${1}"
        else
            echo "## PLACEHOLDER (EMPTY FILE) ##"
        fi
    }

    function __dir() {
        # -a := show hidden files
        # -l := follow links
        tree -a -l "${1}"
    }

    function __ffmpeg() {
        ffprobe -loglevel quiet -show_format -pretty "${1}" 2>&1
    }

    function __image() {
        identify "${f}"
    }

    case "${1}" in
        "file" )
            join_outputs -c __file --format "off" -- "${@:2}"
            ;;
        "dir" )
            join_outputs -c __dir --print-path "never" -- "${@:2}"
            ;;
        "ffmpeg" )
            join_outputs -c __ffmpeg -- "${@:2}"
            ;;
        "image" )
            join_outputs -c __image -- "${@:2}"
            ;;
    esac

    unset -f __file __dir __ffmpeg __image
}

function __archive() {
    function __list() {
        if [[ "${1}" == "tar" ]]; then
            function __f() { tar -tvf "${1}" ; }
            join_outputs -c "__f" -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "man" ]]; then
            function __f() { man -l "${1}" | tail -n +2 ; }
            join_outputs -c "__f" --format "linenumber" -s "separator" -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "man-nvim" ]]; then
            function __f() { man -l "${1}" | tail -n +2 ; }
            join_outputs -c "__f" --format "off" -s "separator" \
                --output "nvim" --output-nvim-extra "-c set filetype=man" \
                -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "7z" ]]; then
            function __f() { 7z l "${1}" | tail -n +19 ; }
            join_outputs -c "__f" -s "separator" -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "7z-nvim" ]]; then
            function __f() { 7z l "${1}" | tail -n +3 ; }
            join_outputs \
                -c "__f" -s "separator" --format "off" --output "nvim" \
                -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "zip" ]]; then
            function __f() { unzip -l "${1}" ; }
            join_outputs -c "__f" -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "unrar" ]]; then
            function __f() { unrar l "${1}" | tail -n +5 | head -n -1 ; }
            join_outputs -c "__f" -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "unrar-nvim" ]]; then
            function __f() { unrar v "${1}" | tail -n +5 | head -n -1 ; }
            join_outputs -c "__f" --format "off" --output "nvim" -- "${@:2}"
            unset -f __f
        else
            if [[ "${2}" == "multi" ]]; then
                local mode="--${1}"
                function __f() { tar "${mode}" -tvf "${1}" ; }
                join_outputs -c "__f" -- "${@:3}"
                unset -f __f
            else
                local mode="${1}"
                function __f() { "${mode}" --keep -d --stdout "${1}" ; }
                join_outputs -c "__f" -- "${@:3}"
                unset -f __f
            fi
        fi
    }

    function __unmake() {
        if [[ "${1}" == "tar" ]]; then
            for f in "${@:2}"; do
                tar -xvf "${f}"
            done
        elif [[ "${1}" == "7z" ]]; then
            for f in "${@:2}"; do
                7z x "${f}"
            done
        elif [[ "${1}" == "zip" ]]; then
            for f in "${@:2}"; do
                unzip "${f}"
            done
        elif [[ "${1}" == "unrar" ]]; then
            for f in "${@:2}"; do
                unrar x "${f}"
            done
        else
            if [[ "${2}" == "multi" ]]; then
                for f in "${@:3}"; do
                    tar --"${1}" -xvf "${f}"
                done
            else
                case "${1}" in
                    "bzip2" )
                        bzip2 --keep -d "${@:3}"
                        ;;
                    "gzip" )
                        gzip --keep -d "${@:3}"
                        ;;
                    "xz" )
                        xz --keep -d "${@:3}"
                        ;;
                    "zstd" )
                        zstd --keep -d "${@:3}"
                        ;;
                esac
            fi
        fi
    }

    function __make() {
        if [[ "${1}" == "tar" ]]; then
            tar -cv -f "_new.tar" -- "${@:2}"
        elif [[ "${1}" == "multi" ]]; then
            case "${2}" in
                "tar" )
                    tar -cv -f "_new.tar" -- "${@:3}"
                    ;;
                "bzip2" )
                    tar --bzip2 -cv -f "_new.tar.bz2" -- "${@:3}"
                    ;;
                "gzip" )
                    tar --gzip -cv -f "_new.tar.gz" -- "${@:3}"
                    ;;
                "xz" )
                    tar --xz -cv -f "_new.tar.xz" -- "${@:3}"
                    ;;
                "zstd" )
                    tar --zstd -cv -f "_new.tar.zst" -- "${@:3}"
                    ;;
                "7z" )
                    7z a "_new.7z" -- "${@:3}"
                    ;;
                "zip" )
                    zip -r "_new.zip" -- "${@:3}"
                    ;;
            esac
        else
            case "${2}" in
                "bzip2" )
                    bzip2 --keep "${@:3}"
                    ;;
                "gzip" )
                    gzip --keep "${@:3}"
                    ;;
                "xz" )
                    xz --keep "${@:3}"
                    ;;
                "zstd" )
                    zstd --keep "${@:3}"
                    ;;
                "7z" )
                    for f in "${@:3}"; do
                        7z a "${f}.7z" -- "${f}"
                    done
                    ;;
                "zip" )
                    for f in "${@:3}"; do
                        zip -r "${f}.zip" -- "${f}"
                    done
                    ;;
            esac
        fi
    }

    case "${1}" in
        "list" )
            __list "${@:2}"
            ;;
        "unmake" )
            __unmake "${@:2}"
            ;;
        "make" )
            __make "${@:2}"
            ;;
    esac

    unset -f __list __unmake __make
}

function __pass() {
    local pass_dir="password-store"  # intentionally without leading dot
    local target
    target=$(
        echo "${2}" | sed "s/^.*\.${pass_dir}\/\(.*\).gpg$/\1/" \
    )

    local pw_time=7
    if [[ "${target}" == *.mfa ]]; then
        PASSWORD_STORE_CLIP_TIME="${pw_time}" \
            pass otp code -c "${target}" 1>/dev/null
    else
        local mode="${1}"
        if [[ "${mode}" == "edit" ]]; then
            pass edit "${target}" 2>/dev/null
        elif [[ "${mode}" == "show" ]]; then
            pass show "${target}" | nvim_ro
        else
            PASSWORD_STORE_CLIP_TIME="${pw_time}" \
                pass -c "${target}" 1>/dev/null
        fi
    fi
}

function main() {
    case "${1}" in
        "nvim" )
            __nvim "${@:2}"
            ;;
        "preview" )
            __preview "${@:2}"
            ;;
        "mpv" | "imv" | "zathura" | "pdfarranger" | "xournalpp" | "lyx" | "libreoffice" | "sqlitebrowser" )
            spawn_proc "${1}" "${@:2}"
            ;;
        "archive" )
            __archive "${@:2}"
            ;;
        "pass" )
            __pass "${@:2}"
            ;;
    esac

    unset -f __nvim __preview __tree __archive __pass
}
main "${@}"
unset -f main
