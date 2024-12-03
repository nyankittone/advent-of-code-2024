#!/usr/bin/env bash

# $1 is the pre-value
# $2 is the maybe new value
validate_direction() {
    if [ "$1" = idk ]; then
        echo -E "$2"
    else
        echo -E "$1"
        if [ "$1" != "$2" ]; then
            return 1
        fi
    fi
}

recover_unsafe() {
:
}

# $1 is the previous
# $2 is the current
# $3 is the next
# $4 is the direction
# Output is what the value of $direction in validate_report() should be, and an extra line to signal skipping
# iteration
validate_level() {
    echo -E "prev: $1" "curr: $2" 1>&2

    local difference
    difference=$(($1 - $2))

    [ "$difference" -gt 3 ] || [ "$difference" -lt -3 ] || [ "$difference" = 0 ] && {
        echo -E "$4"
        echo -E "go"
        return 1
    }

    local capture
    case "$difference" in
        -*) capture="$(validate_direction "$4" up)";;
        *) capture="$(validate_direction "$4" down)";;
    esac || {
        echo -E "$capture"
        echo -E "go"
        return 1
    }

    echo -E "$capture"
    echo -E "go"
}

# $1 is the report (a line of text with numbers)
validate_report() {
    # take the first token, and use that to compare against
    # loop over all other tokens, running the check on each iteration
    # if the check is false on any loop, return 1
    # return 0 if we get to the end of the loop

    # For part 2, we need to add extra context to our loop.
    #

    local previous_token
    previous_token=$(echo -E "$1" | awk '{print $1}')
    local current_token
    current_token=$(echo -E "$1" | awk '{print $2}')
    local remaining
    remaining=$(echo -E "$1" | sed -E 's/^\s*[0-9]+\s+[0-9]+\s*//')

    local direction
    direction=idk

    for next_token in $remaining; do
        echo direction is "$direction" 1>&2
        local capture
        capture=$(validate_level "$previous_token" "$current_token" "$next_token" "$direction")
        if [ "$?" != 0 ]; then
            echo Rats! 1>&2
            return 1
        fi

        direction=$(echo -E "$capture" | head -n1)
        previous_token="$current_token"
        current_token="$next_token"
    done

    local fake_token
    case "$direction" in
        up) fake_token=$((current_token + 1));;
        down) fake_token=$((current_token - 1));;
    esac
    validate_level "$previous_token" "$current_token" "$fake_token" "$direction" 1>/dev/null || return 1

    echo OK! 1>&2
    return 0
}

load_file() {
    if [ -n "$1" ]; then
        if ! cat -- "$1"; then
            exit 1
        fi
    else
        cat
    fi
}

load_file "$1" | while read -r line; do
    validate_report "$line" && echo -E "$line"
done | wc -l | xargs -I % echo % reports are safe.

