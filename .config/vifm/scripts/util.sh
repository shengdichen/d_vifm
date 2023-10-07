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
    local sep="${1:-/}"

    printf "\n"
    printf "%0.s${sep}" {1..79}
    printf "\n\n"
}

function join_with_linebreak() {
    for f in "${@:2}"; do
        echo "Path: ${f}"
        "${1}" "${f}"
        echo
    done | head -n -1
}
