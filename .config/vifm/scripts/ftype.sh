source "util.sh"

function tar_multi_single() {
    local type="" multis=() singles=() ambivalents=()
    while (( ${#} > 0 )); do
        case "${1}" in
            "-t" )
                type="${2}"
                shift; shift ;;
            "-m" )
                multis+=("${2}")
                shift; shift ;;
            "-s" )
                singles+=("${2}")
                shift; shift ;;
            "--" )
                ambivalents=("${@:2}")
                break ;;
        esac
    done

    if __match -s "${multis[@]}"; then
        echo "${type}-multiple"
        return
    elif __match -s "${singles[@]}"; then
        echo "${type}-single"
        return
    else
        local p
        for p in "${ambivalents[@]}"; do
            if __match -s "${p}"; then
                if match_pattern -n "${fname}" -f tar "${p}"; then
                    echo "${type}-multiple"
                else
                    echo "${type}-single"
                fi
                return
            fi
        done
    fi
    false
}

function ftype() {
    local name="${1}"
    function __match() {
        match_patterns -n "${name}" "${@}"
    }

    if __match -s tar; then
        echo "tar"
    elif __match -s 7z iso; then
        echo "7z"
    elif __match -s zip apk apkg ear jar war; then
        echo "zip"
    elif __match -s rar; then
        echo "rar"
    elif tar_multi_single -t gzip -m tbz2 -m tbz -- bz2 bz; then
        return
    elif tar_multi_single -t gzip -m tgz -m taz -- gz; then
        return
    elif tar_multi_single -t xz -m txz -m tlz -s lzma -- xz lz; then
        return
    elif tar_multi_single -t zst -- zst; then
        return
    fi

    unset -f __multi
}

function __test() {
    #   fname="x.tar"; ftype
    #   fname="x.tz"; ftype
    #   fname="x.iso"; ftype
    #   fname="x.zip"; ftype
    #   fname="x.apk"; ftype
    #   [[ fname="x.rar"; ftype == "rar" ]]

    #   fname="x.tar.zst"; ftype
    ftype "x.tar"
}

run_test=false
shift
while (( ${#} > 0 )); do
    case "${1}" in
        "--run-test" )
            run_test=true
            shift ;;
        * )

    esac
done

if [[ "${2}" == "--test" ]]; then
    __test
else
    ftype
fi
unset fname
unset -f __match tar_multi_single ftype __test
