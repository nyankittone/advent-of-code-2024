#!/usr/bin/env bash

# Ok, so we have a word search. We must find "XMAS" for all directions (including diagonal!)
# Here's a funny way to solve this: what if we only try to solve for finding "XMAS" left-to-right?
# And to get everything else, we just transform the word search input in various ways, using rev,
# somehow rotating the whole thing by 90 degrees? Oh yeah, and also rotating diagonally?
# If I can somehow get away with this, I can get by by just using `grep -o` to get occurrences of
# "XMAS", and get how many for each transform with `wc -l`. Sum it up, and I might have an answer.

# For some reason, this program outputs the wrong answer on the full data set... I don't understand
# why; there's no good lead I have for why this happens, but sad. I must fix this or restart with
# just an array...

log() {
    echo "$@" 1>&2
}

load_file() {
    if [ -n "$1" ]; then
        cat -- "$1"
    else
        cat
    fi
}

# Rotate 90 degrees to the left.
# $1 is the input board.
rotate() {
    # All input lines are the same size, so we sholud be able to safely get the length of the board
    # with wc -L.
    # we can use cut to get just an individual column.

    local length
    length=$(echo -E "$1" | wc -L)
    local i
    i=1

    local returned
    returned=

    while [ "$i" -le "$length" ]; do
        returned="$(echo -E "$1" | cut -c$i | tr -d '\n')"$'\n'"$returned"
        i=$((i + 1))
    done

    echo -En "$returned"
}

# $1 is the text input
slant_left() {
    # Gonna try to use awk to create a slant from right to left. 
    local lines
    lines=$(echo -E "$1" | wc -l)
    echo -E "$1" | awk '{print sprintf("%*s", '"$lines"' - ++i, "")$0sprintf("%*s", i - 1, "")}'
}

# $1 is the text input
slant_right() {
    # Gonna try to use awk to create a slant from left to right. 
    local lines
    lines=$(echo -E "$1" | wc -l)
    echo -E "$1" | awk '{print sprintf("%*s", i++, "")$0sprintf("%*s", '"$lines"' - i, "")}'
}

# $1 is the input word search
do_the_thing() {
    local final_sum
    local sum

    sum=$(echo -E "$1" | grep -oc XMAS)
    printf 'no transform: %s\n' "$sum"
    final_sum=$((final_sum + sum))

    local transd
    transd=$(echo -E "$1" | rev)
    sum=$(echo -E "$transd" | grep -oc XMAS)
    printf 'mirrored: %s\n' "$sum"
    final_sum=$((final_sum + sum))

    transd=$(rotate "$1")
    sum=$(echo -E "$transd" | grep -oc XMAS)
    printf 'rotated: %s\n' "$sum"
    final_sum=$((final_sum + sum))

    transd=$(echo -E "$transd" | rev)
    sum=$(echo -E "$transd" | grep -oc XMAS)
    printf 'rotated + mirrored: %s\n' "$sum"
    final_sum=$((final_sum + sum))

    # now i gotta do the diagonals lmao
    # SLANT_LEFT
    transd=$(rotate "$(slant_left "$1")")
    sum=$(echo -E "$transd" | grep -oc XMAS)
    printf 'left slant + rotated: %s\n' "$sum"
    final_sum=$((final_sum + sum))

    transd=$(echo -E "$transd" | rev)
    sum=$(echo -E "$transd" | grep -oc XMAS)
    printf 'left slant + rotated + mirrored: %s\n' "$sum"
    final_sum=$((final_sum + sum))

    # SLANT_RIGHT
    transd=$(rotate "$(slant_right "$1")")
    sum=$(echo -E "$transd" | grep -oc XMAS)
    printf 'right slant + rotated: %s\n' "$sum"
    final_sum=$((final_sum + sum))

    transd=$(echo -E "$transd" | rev)
    sum=$(echo -E "$transd" | grep -oc XMAS)
    printf 'right slant + rotated + mirrored: %s\n' "$sum"
    final_sum=$((final_sum + sum))

    printf 'XMAS occurs %s times.\n' "$final_sum"
}

return 0 2>/dev/null
set -e

do_the_thing "$(load_file "$1")"
# slant_right "$(load_file "$1")"
# rotate "$(slant_right "$(load_file "$1")")"

diff <(load_file "$1") <(rotate "$(rotate "$(rotate "$(rotate "$(load_file "$1")")")")")

