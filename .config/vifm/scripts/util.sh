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
