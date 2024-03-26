source "util.sh"

function __archive() {
    function __list() {
        if [[ "${1}" == "man" ]]; then
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
        fi
    }

    case "${1}" in
        "list")
            __list "${@:2}"
            ;;
    esac
    unset -f __list
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

    unset -f __archive __pass __spectrogram
}
main "${@}"
unset -f main
