#!/usr/bin/env bash

top='M.M'$'\n''.A.'$'\n''S.S'
left='S.M'$'\n''.A.'$'\n''S.M'
bottom='S.S'$'\n''.A.'$'\n''M.M'
right='M.S'$'\n''.A.'$'\n''M.S'

# $1 is the subsection to check.
# $2 is the mask to use.
# 0 is returned on a successful match. Otherwise, 1 is returned.
shitty_validate_subsection() {
    # match top line with top line    
    # match middle line with middle line    
    # match bottom line with bottom line    
    # ALL lines must match for a successful match.
    
    sed '1p;d' <<< "$1" | grep "$(sed '1p;d' <<< "$2")" &&
    sed '2p;d' <<< "$1" | grep "$(sed '2p;d' <<< "$2")" &&
    sed '3p;d' <<< "$1" | grep "$(sed '3p;d' <<< "$2")"
}

# $1 is the subsection to check.
# 0 is returned on a successful match. Otherwise, 1 is returned.
validate_subsection() {
    shitty_validate_subsection "$1" "$top" ||
    shitty_validate_subsection "$1" "$left" ||
    shitty_validate_subsection "$1" "$bottom" ||
    shitty_validate_subsection "$1" "$right"
}

solve_the_thing() {
    local the_grid
    the_grid=$(cat)

    # get the length and height of the word search
    local length
    local height
    length=$(($(wc -L <<< "$the_grid") - 2))
    height=$(($(wc -l <<< "$the_grid") - 2))

    echo "length is ${length}, height is ${height}"

    # iterate over each possible place that our masks can fit in the word search
    local ix
    local iy
    local sum
    iy=1
    sum=0

    while [ "$iy" -le "$height" ]; do
        ix=1

        while [ "$ix" -le "$length" ]; do
            # get the subsection needed with sed and cut
            local subsection
            subsection=$(sed "$iy,$((iy + 2))"'p;d' <<< "$the_grid" | cut -c"$ix-$((ix + 2))")

            # send the subsection off to the validator function
            if validate_subsection "$subsection"; then
                sum=$((sum + 1))
            fi

            ix=$((ix + 1))
        done

        iy=$((iy + 1))
    done

    echo -E "$sum"
}

load_file() {
    if [ -n "$1" ]; then
        cat -- "$1" || kill -9 "$$"
    else
        cat
    fi
}

return 0 2>/dev/null
set -e

load_file "$1" | solve_the_thing

