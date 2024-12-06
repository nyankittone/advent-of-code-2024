#!/usr/bin/env bash

# How tf do I do this in Bash????
# load the data
# Somehow get the position of the guard???
## We can use `grep -n` to get the Y position of the guard
## Can also use `grep -bo` to get the X position of the guard
## The guard starts at an upwards position. We can simply just grep for '\^'.

# How to move()?
# We need 4 functions, one for each direction
# for each, we generally need to:
## Switch the function to use for next time
## change the guard's coords
## (the maybe tricky part) write Xs to all of the spaces travelled by the guard

# $1 is the map
# first line of stdout is the X
# second line of stdout is the Y
init_guard() {
    local x_position
    y_position=$(grep -n '\^' <<< "$1" | cut -d: -f1)
    echo "guard_y=$y_position"
    echo "guard_x=$(($(awk '{if(++i == '"$y_position"') print}' <<< "$1" | grep -bo '\^' | cut -d: -f1) + 1))"
    echo 'guard_move=move_up'
}

# $1 is the input map
# stdout is a new output map with the X's in the right places
# 1 is returned if the guard runs into the map edge.
move_up() {
    # cut the map to the current column
    local column
    local column_info
    column=$(cut -c "$guard_x" <<< "$1")
    column_info=$(grep -n '#' <<< "$column")
    if [ "$?" != 0 ]; then
        guard_y=1
        return 1
    fi

    # Find the largest Y value less than or greater to guard_y
    local old_guard_y
    old_guard_y=$guard_y
    guard_y=$(cut -d: -f1 <<< "$column_info" | awk '{if($0 < '"$guard_y"') {result=$0} else exit} END{print result}')
    guard_y=$((guard_y + 1))

    # Modify the OG map with X's in the right places
    column=$(sed "$guard_y,$old_guard_y"'s/.*/X/' <<< "$column")
    map="$(paste <(cut -c1-$((guard_x - 1)) <<< "$1") <(echo -E "$column") <(cut -c$((guard_x + 1))- <<< "$1") | tr -d '\t')"

    guard_move=move_right
    echo -E "y is $guard_y" 1>&2
    return 0
}

# $1 is the input map
# stdout is a new output map with the X's in the right places
# 1 is returned if the guard runs into the map edge.
move_right() {
    # Get line for the guard's Y position
    local line

    guard_move=move_down
    return 0
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

map=$(load_file "$1")
eval `init_guard "$map"`
echo "$guard_y"
"$guard_move" "$map"
echo "$map"
echo -E "y is $guard_y" 1>&2
echo "$guard_move"
