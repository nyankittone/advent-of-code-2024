#!/usr/bin/env bash

# $1 is the report
# return successfully only if safe
validate_report() {
    local first_token
    local remaining
    first_token=$(echo -E "$1" | awk '{print $1}')
    remaining=$(echo -E "$1" | sed -E 's/^\s*[0-9]+\s+//')

    local i
    i=1

    local direction
    direction=idk

    for current_token in $remaining; do
        local difference
        difference=$((current_token - first_token))

        # check if difference is too big or not
        if [ "$difference" = 0 ] || [ "$difference" -lt -3 ] || [ "$difference" -gt 3 ]; then
            return "$i"
        fi

        # check if difference is going in the right direction
        if [ "$direction" = idk ]; then
            case "$difference" in
                -*) direction=down;;
                *) direction=up;;
            esac
        elif [ "${difference:0:1}" = '-' ] && [ "$direction" = up ]; then
            return "$i"
        elif [ "${difference:0:1}" != '-' ] && [ "$direction" = down ]; then
            return "$i"
        fi

        first_token=$current_token
        i=$((i + 1))
    done

    return 0
}

# $1 is the report line
# 0 is returned only when report is safe
problem_dampen() {
    local failed_index
    validate_report "$1"
    failed_index=$?

    [ "$failed_index" = 0 ] && return 0

    # try removing fields from the input with sed
    local new_report
    new_report=$(echo -E "$1" | tr ' ' '\n' | sed "$failed_index"d | tr '\n' ' ')

    validate_report "$new_report" && return 0
    new_report=$(echo -E "$1" | tr ' ' '\n' | sed "$((failed_index + 1))"d | tr '\n' ' ')

    validate_report "$new_report" && return 0
    new_report=$(echo -E "$1" | tr ' ' '\n' | sed 1d | tr '\n' ' ')

    validate_report "$new_report"
}

load_file() {
    if [ -n "$1" ]; then
        cat -- "$1"
    else
        cat
    fi
}

return 0 2>/dev/null
set -e

load_file "$1" | while read -r line; do
    if problem_dampen "$line"; then
        echo -E "$line"
    fi
done

