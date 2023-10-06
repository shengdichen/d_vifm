function truncate_longline() {
    cat - | fold -w 119 -s
}

function prepend_linenumber() {
    cat - | nl -b a -w 2 -n 'rz' -s '  '
}

function format_standard() {
    cat - | truncate_longline | prepend_linenumber
}
