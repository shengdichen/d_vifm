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
        "spectrogram")
            __spectrogram "${@:2}"
            ;;
    esac

    unset -f __spectrogram
}
main "${@}"
unset -f main
