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

# Is $1 supposed to occur before $2?
# If true, return 0, else 1.
# If we don't know, also return 0.
# I have some performance concerns with this code.
is_before() {
    grep '^'"$1"'|'"$2"'$' || grep '^'"$2"'|'"$1"'$' && return 1
    return 0
}

# stdin is the lists of pages
# $1 is the ordering rules
# stdout is the input with all the bad inputs filtered out
filter_bad_lists() {
    while true; do
        # WHY IS READ GIVING A BAD EXIT CODE ON THE SECOND LOOP???? BLEHHH
        echo new loop 1>&2
        local bruh
        read -r bruh
        echo -E "$bruh"  1>&2

        local fields
        IFS=, read -ra fields <<< "$bruh"

        local continue_flag
        local i
        i=0

        while [ "$i" -lt "${#fields[@]}" ]; do
            local ii
            ii=0

            while [ "$ii" -lt "${#fields[@]}" ]; do
                if [ "$ii" -eq "$i" ]; then
                    ii=$((ii + 1))
                elif [ "$ii" -lt "$i" ]; then
                    # do thing or something
                    if ! is_before "${fields[$ii]}" "${fields[$i]}"; then
                        continue_flag=yes
                        break
                    fi
                else
                    # do similar but other thing or somthn, what am I, a programmer?
                    if ! is_before "${fields[$i]}" "${fields[$ii]}"; then
                        continue_flag=yes
                        break
                    fi
                fi

                ii=$((ii + 1))
            done

            [ -n "$continue_flag" ] && break
            i=$((i + 1))
        done

        [ -n "$continue_flag" ] && continue
        echo -E "${fields[@]}"
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

echo -E "$page_lists" | filter_bad_lists "$ordering_rules"

