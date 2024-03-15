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
        # -L 1 := list only immediate children
        tree -a -l -L 1 --filelimit 197 "${1}"
    }

    function __ffmpeg() {
        ffprobe -loglevel quiet -show_format -pretty "${1}" 2>&1
    }

    function __image() {
        identify "${f}"
    }

    case "${1}" in
        "file")
            join_outputs -c __file --format "off" -- "${@:2}"
            ;;
        "dir")
            join_outputs -c __dir --print-path "never" -- "${@:2}"
            ;;
        "ffmpeg")
            join_outputs -c __ffmpeg -- "${@:2}"
            ;;
        "image")
            join_outputs -c __image -- "${@:2}"
            ;;
    esac

    unset -f __file __dir __ffmpeg __image
}

function __archive() {
    function __list() {
        if [[ "${1}" == "tar" ]]; then
            function __f() { tar -tvf "${1}"; }
            join_outputs -c "__f" -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "man" ]]; then
            function __f() { man -l "${1}" | tail -n +2; }
            join_outputs -c "__f" \
                --format "linenumber" -s "separator" \
                -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "man-nvim" ]]; then
            function __f() { man -l "${1}" | tail -n +2; }
            join_outputs -c "__f" \
                --format "off" -s "separator" \
                --output "nvim" --output-nvim-extra "-c set filetype=man" \
                -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "7z" ]]; then
            function __f() { 7z l "${1}" | tail -n +19; }
            join_outputs -c "__f" -s "separator" -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "7z-nvim" ]]; then
            function __f() { 7z l "${1}" | tail -n +3; }
            join_outputs -c "__f" \
                --format "off" -s "separator" --output "nvim" \
                -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "zip" ]]; then
            function __f() { unzip -l "${1}" | tail -n +2; }
            join_outputs -c "__f" -s "separator" -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "unrar" ]]; then
            function __f() { unrar l "${1}" | tail -n +5 | head -n -1; }
            join_outputs -c "__f" -s "separator" -- "${@:2}"
            unset -f __f
        elif [[ "${1}" == "unrar-nvim" ]]; then
            function __f() { unrar v "${1}" | tail -n +5 | head -n -1; }
            join_outputs -c "__f" \
                --format "off" -s "separator" --output "nvim" \
                -- "${@:2}"
            unset -f __f
        else
            if [[ "${2}" == "multi" ]]; then
                local mode="--${1}"
                function __f() { tar "${mode}" -tvf "${1}"; }
                join_outputs -c "__f" -- "${@:3}"
                unset -f __f
            else
                local mode="${1}"
                function __f() { "${mode}" --keep -d --stdout "${1}"; }
                join_outputs -c "__f" -- "${@:3}"
                unset -f __f
            fi
        fi
    }

    function __unmake() {
        local type mode
        while ((${#} > 0)); do
            case "${1}" in
                "-t" | "--type")
                    type="${2}"
                    shift
                    shift
                    ;;
                "-m" | "--mode")
                    mode="${2}"
                    shift
                    shift
                    ;;
                "--")
                    files=("${@:2}")
                    break
                    ;;
            esac
        done

        if [[ "${type}" == "tar" ]]; then
            function __f() { tar -xvf "${1}"; }
        elif [[ "${type}" == "7z" ]]; then
            function __f() { 7z x "${1}"; }
        elif [[ "${type}" == "zip" ]]; then
            function __f() { unzip "${1}"; }
        elif [[ "${type}" == "unrar" ]]; then
            function __f() { unrar x "${1}"; }
        else
            if [[ "${mode}" == "multi" ]]; then
                function __f() { tar "--${type}" -xvf "${1}"; }
            else
                function __f() { "${type}" --keep -d "${1}"; }
            fi
        fi
        join_outputs -c "__f" \
            --print-path "always" -s "separator" \
            -- "${files[@]}"
        unset -f __f
    }

    function __make() {
        local type mode
        while ((${#} > 0)); do
            case "${1}" in
                "-t" | "--type")
                    type="${2}"
                    shift
                    shift
                    ;;
                "-m" | "--mode")
                    mode="${2}"
                    shift
                    shift
                    ;;
                "--")
                    files=("${@:2}")
                    break
                    ;;
            esac
        done

        if [[ "${type}" == "tar" ]]; then
            function __f() { tar -cv -f "_new.tar" -- "${@}"; }
        elif [[ "${mode}" == "multi" ]]; then
            case "${type}" in
                "bzip2")
                    function __f() { tar "--${type}" -cv -f "_new.tar.bz2" -- "${@}"; }
                    ;;
                "gzip")
                    function __f() { tar "--${type}" -cv -f "_new.tar.gz" -- "${@}"; }
                    ;;
                "xz")
                    function __f() { tar "--${type}" -cv -f "_new.tar.${type}" -- "${@}"; }
                    ;;
                "zstd")
                    function __f() { tar "--${type}" -cv -f "_new.tar.zst" -- "${@}"; }
                    ;;
                "7z")
                    function __f() { 7z a "_new.7z" -- "${@}"; }
                    ;;
                "zip")
                    function __f() { zip -r "_new.zip" -- "${@}"; }
                    ;;
            esac
        else
            case "${type}" in
                "bzip2" | "gzip" | "xz" | "zstd")
                    function __f() { "${type}" --keep "${@}"; }
                    ;;
                "7z")
                    function __f() {
                        for f in "${@}"; do
                            7z a "${f}.7z" -- "${f}"
                        done
                    }
                    ;;
                "zip")
                    function __f() {
                        for f in "${@}"; do
                            zip -r "${f}.zip" -- "${f}"
                        done
                    }
                    ;;
            esac
        fi

        __f "${files[@]}"
    }

    case "${1}" in
        "list")
            __list "${@:2}"
            ;;
        "unmake")
            __unmake "${@:2}"
            ;;
        "make")
            __make "${@:2}"
            ;;
    esac

    unset -f __list __unmake __make
}

function __pass() {
    local pass_dir="password-store" # intentionally without leading dot
    local target
    target=$(
        echo "${2}" | sed "s/^.*\.${pass_dir}\/\(.*\).gpg$/\1/"
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

function __spectrogram() {
    local suffix="png" outputs=()
    for f in "${@}"; do
        output="${f}.${suffix}"
        sox "${f}" -n spectrogram -o "${output}"
        outputs+=("${output}")
    done
    spawn_proc imv "${outputs[@]}"
}

function main() {
    case "${1}" in
        "nvim")
            __nvim "${@:2}"
            ;;
        "preview")
            __preview "${@:2}"
            ;;
        "mpv" | "imv" | "zathura" | "pdfarranger" | "xournalpp" | "lyx" | "libreoffice" | "sqlitebrowser")
            spawn_proc "${1}" "${@:2}"
            ;;
        "archive")
            __archive "${@:2}"
            ;;
        "pass")
            __pass "${@:2}"
            ;;
        "spectrogram")
            __spectrogram "${@:2}"
            ;;
    esac

    unset -f __nvim __preview __tree __archive __pass __spectrogram
}
main "${@}"
unset -f main
