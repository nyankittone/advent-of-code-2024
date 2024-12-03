#!/usr/bin/env bash

set -e

load_file() {
    if [ -n "$1" ]; then
        cat -- "$1"
    else
        cat
    fi
}

return 0 2>/dev/null || true

# Top 10 Bash one-liners
load_file "$1" |
    sed -z 's/\n//g;s/^/do()/;s/do()\+/\n&/g;s/don'"'"'t()\+/\n&/g' |
    sed '1d;/^don/d' |
    grep -Eo 'mul\([0-9]+,[0-9]+\)' |
    sed 's/^mul(//;s/,/ * /;s/)$//' |
    xargs -n 3 expr |
    tr '\n' '+' |
    sed 's/+$//;s/+/ + /g' |
    xargs -d ' ' expr

