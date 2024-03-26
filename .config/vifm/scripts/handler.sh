source "util.sh"

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
        "pass")
            __pass "${@:2}"
            ;;
        "spectrogram")
            __spectrogram "${@:2}"
            ;;
    esac

    unset -f __pass __spectrogram
}
main "${@}"
unset -f main
