function truncate_longline() {
    local len_max=${1}
    fold -w "${len_max}" -s
}

function prepend_linenumber() {
    nl -b a -w 2 -n 'rz' -s '  '
}

function format_standard() {
    local len_max="${1:-119}"
    truncate_longline "${len_max}" | prepend_linenumber
}

function format_output() {
    local width=119
    local linenumber=true
    local files=()
    while (( ${#} > 0 )); do
        case "${1}" in
            "-w" | "--max-width" )
                width="${2}"
                shift; shift
                ;;
            "--no-linenumber" )
                linenumber=false
                shift; shift
                ;;
            "--" )
                files=("${@:2}")
                break
        esac
    done

    if (( ${#files[@]} > 0 )); then
        cat "${files[@]}"
    else
        cat
    fi | \
    if [[ "${width}" != "off" ]]; then
        fold -w "${width}" -s
    else
        cat
    fi | \
    if "${linenumber}"; then
        nl -b a -w 2 -n 'rz' -s '  '
    else
        cat
    fi
}

function nvim_ro() {
    # NOTE::
    #   (n)vim prefers files passed as cmd-arg over stdin, e.g.,
    #   -> $ ls | nvim ""
    #   will open current directory instead of reading stdin
    #
    #   here, only forward to (n)vim if the one arg is not the empty-string

    function __f() {
        nvim -R -c "set nomodifiable" "${@}"
    }

    if (( ${#} > 1 )); then
        __f "${@}"
    elif [[ -n "${1}" ]]; then
        __f "${1}"
    else
        __f
    fi
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
    local format="standard"
    local output="stdout" output_nvim_extra=""
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
            "--format" )
                format="${2}"
                shift; shift
                ;;
            "--output" )
                if [[ "${2}" == "stdout" || "${2}" == "nvim" ]]; then
                    output="${2}"
                fi
                shift; shift
                ;;
            "--output-nvim-extra" )
                output_nvim_extra="${2}"
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
        "${cmd}" "${f}" | \
        case "${format}" in
            "standard") format_output;;
            "linenumber") format_output -w "off";;
            "off") cat;;
        esac
        $separator
    done | head -n "-${separator_cutaway}" | \
        if [[ "${output}" == "nvim" ]]; then
            nvim_ro "${output_nvim_extra}"
        else
            cat
        fi
}
