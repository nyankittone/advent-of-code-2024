#!/usr/bin/env bash

# Day 1
# Our puzzle input contains 2 columns of numbers
# so what to do?
# - split input into two
# - sort them
# - iterate over both at the same time
# -- for each, get abs($1 - $2)
# -- add that to a sum
# -- return the sum

# $1 is left input file
# $2 is right input file
get_answer() {
    local returned
    returned=0

    local l_left
    local l_right
    l_left=$(printf '%s\n' "$1" | tr '\n' ' ')
    l_right=$(printf '%s\n' "$2" | tr '\n' ' ')

    for i in `seq $3`; do
        local left_digit
        left_digit=$(printf '%s\n' "$l_left" | awk '{print $1}')
        l_left=$(printf '%s\n' "$l_left" | sed 's/^\s*[0-9]*\s*//')
        echo "left: $left_digit" 1>&2

        local right_digit
        right_digit=$(printf '%s\n' "$l_right" | awk '{print $1}')
        l_right=$(printf '%s\n' "$l_right" | sed 's/^\s*[0-9]*\s*//')
        echo "right: $right_digit" 1>&2

        # do the subtraction
        local difference
        difference=$((left_digit - right_digit))
        case "$difference" in
            -*) difference=${difference:1};;
            *);;
        esac

        returned=$((returned + difference))
    done

    echo "$returned"
}

# $1 is text for the input
# $2 is a file for the second input
# $3 is the input line size
get_similarity() {
    local returned
    returned=0

    local l_left
    l_left=$(printf '%s\n' "$1" | tr '\n' ' ')

    for i in `seq $3`; do
        local left_digit
        left_digit=$(printf '%s\n' "$l_left" | awk '{print $1}')
        l_left=$(printf '%s\n' "$l_left" | sed 's/^\s*[0-9]*\s*//')
        echo "left: $left_digit" 1>&2

        local occurences
        occurences=$(grep "$left_digit" <(printf '%s\n' "$2") | wc -l)
        echo "occur: $occurences" 1>&2

        returned=$((left_digit * occurences + returned))
    done

    echo "$returned"
}

get_input() {
    if [ -n "$1" ]; then
        if ! cat "$1"; then
            exit 1
        fi
    else
        cat
    fi
}

input=$(get_input "$@")
left=$(echo "$input" | cut -d' ' -f1 | sort -g)
right=$(echo "$input" | awk '{print $2}' | sort -g)

get_answer "$left" "$right" "$(printf '%s\n' "$left" | wc -l)" | xargs echo The sum is
get_similarity "$left" "$right" "$(printf '%s\n' "$left" | wc -l)" | xargs echo the similarity is
