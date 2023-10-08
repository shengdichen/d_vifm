function truncate_longline() {
    local len_max=${1}
    cat - | fold -w "${len_max}" -s
}

function prepend_linenumber() {
    cat - | nl -b a -w 2 -n 'rz' -s '  '
}

function format_standard() {
    local len_max="${1:-119}"
    cat - | truncate_longline "${len_max}" | prepend_linenumber
}

function nvim_ro() {
    cat - | nvim -R -c "set nomodifiable" "${@}"
}

function spawn_proc() {
    nohup "${@}" 1>/dev/null 2>&1 &
}

function insert_separator() {
    local char="/" len="79"
    while (( ${#} > 0 )); do
        case "${1}" in
            "-c" | "--char" )
                char="${2}"
                shift; shift
                ;;
            "-l" | "len" )
                len="${2}"
                shift; shift
                ;;
        esac
    done

    printf "\n"
    printf "%0.s${char}" $(seq "${len}")
    printf "\n\n"
}

function join_outputs() {
    local separator="echo" separator_cutaway="1"
    local print_path="multiple"
    local n_files="0"
    while (( ${#} > 0 )); do
        case "${1}" in
            "-c" | "--cmd" )
                local cmd="${2}"
                shift; shift
                ;;
            "-s" | "--separator" )
                if [[ "${2}" == "separator" ]]; then
                    separator="insert_separator" separator_cutaway="3"
                fi
                shift; shift
                ;;
            "--print-path" )
                print_path="${2}"
                shift; shift
                ;;
            "--" )
                local files=("${@:2}")
                n_files="${#files[@]}"
                break
        esac
    done

    for f in "${files[@]}"; do
        if [[ \
            "${print_path}" == "always" || \
            ("${print_path}" == "multiple" && "${n_files}" -gt 1) \
        ]]; then
            echo "Path: ${f}"
        fi
        "${cmd}" "${f}"
        $separator
    done | head -n "-${separator_cutaway}"
}
