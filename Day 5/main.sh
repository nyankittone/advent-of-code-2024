#!/usr/bin/env bash

# So, the input actually contains two parts:
# Page ordering rules, and
# Comma-delimited list of pages to include.
# These two things are separated by a double newline. We can use awk to find the line containing
# no contents, and then split each end off into individual variables using head and tail.

# filter out the page lists that are not ordered right
# get the middle number of each list
# sum it all up

load_file() {
    if [ -n "$1" ]; then
        cat -- "$1" || kill -9 "$$"
    else
        cat
    fi
}

# $3 is the ordering rules.
# Is $1 supposed to occur before $2?
# If true, return 0, else 1.
# If we don't know, also return 0.
# I have some performance concerns with this code.
is_before() {
    # echo -E "$1 before $2?"
    if (echo -E "$3" | grep '^'"$1"'|'"$2"'$' >/dev/null); then
        # echo -E YES
        return 0
    elif (echo -E "$3" | grep '^'"$2"'|'"$1"'$' >/dev/null); then
        # echo -E NO
        return 1
    fi

    # echo -E WHEN YOU
    return 0
}

# $1 is the ordering rules
# all other arguments are for the passed in array
try_fix() {
    local i
    i=0

    local rules
    rules=$1
    shift

    local array
    array=("$@")

    local continue_flag

    while [ "$i" -lt "${#array[@]}" ]; do
        local ii
        ii=$((i + 1))

        while [ "$ii" -lt "${#array[@]}" ]; do
            if ! is_before "${array[$i]}" "${array[$ii]}" "$rules"; then
                local tmp
                tmp=${array[i]}
                array[i]=${array[ii]}
                array[ii]=$tmp

                i=0
                ii=1
                continue_flag=yes
                break
            fi

            ii=$((ii + 1))
        done

        if [ -n "$continue_flag" ]; then
            continue_flag=
            continue
        fi

        i=$((i + 1))
    done

    echo -E "${array[@]}"
}

# stdin is the lists of pages
# $1 is the ordering rules
# stdout is the input with all the bad inputs filtered out
filter_bad_lists() {
    local another_effing_counter
    another_effing_counter=1

    while true; do
        echo -E "loop $another_effing_counter" 1>&2
        another_effing_counter=$((another_effing_counter + 1))

        local fields
        IFS=, read -ra fields || break

        local continue_flag
        continue_flag=
        local i
        i=0

        while [ "$i" -lt "${#fields[@]}" ]; do
            local ii
            ii=$((i + 1))

            while [ "$ii" -lt "${#fields[@]}" ]; do
                if ! is_before "${fields[$i]}" "${fields[$ii]}" "$1"; then
                    # swap the offending elements and try again lmao
                    try_fix "$1" "${fields[@]}"
                    continue_flag=yes
                    break
                fi

                ii=$((ii + 1))
            done

            [ -n "$continue_flag" ] && break
            i=$((i + 1))
        done

        [ -n "$continue_flag" ] && continue
    done
}

return 0 2>/dev/null
set -e

full_input=$(load_file "$1")
split_point=$(echo -E "$full_input" | awk '/^$/{print NR-1}')
line_count=$(echo -E "$full_input" | wc -l)

ordering_rules=$(echo -E "$full_input" | head -n"$split_point")
page_lists=$(echo -E "$full_input" | tail -n"$((line_count - split_point - 1))")

unset -v line_count
unset -v split_point

echo -E "$page_lists" | filter_bad_lists "$ordering_rules" | awk '{print $(NF/2+1)}' |
    tr '\n' ' ' | sed 's/ $//;s/ / + /g' | xargs -d ' ' expr
# echo -E "$page_lists" | test_function

