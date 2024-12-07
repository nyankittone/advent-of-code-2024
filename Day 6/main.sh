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

# $1 is the column to use
# $2 is the low coord
# $3 is the high coord
modmap_vert() {
    # Modify the OG map with X's in the right places
    local column
    column=$(sed "$2,$3"'s/.*/X/' <<< "$1")
    map="$(paste <(cut -c1-$((guard_x - 1)) <<< "$map") <(echo -E "$column") <(cut -c$((guard_x + 1))- <<< "$map") | tr -d '\t')"
}

# $1 is the input map
# stdout is a new output map with the X's in the right places
# 1 is returned if the guard runs into the map edge.
move_up() {
    echo up
    # cut the map to the current column
    local column
    local column_info
    local old_guard_y
    old_guard_y=$guard_y
    column=$(cut -c "$guard_x" <<< "$map")
    column_info=$(grep -n '#' <<< "$column")
    if [ "$?" != 0 ]; then
        guard_y=1
        modmap_vert "$column" "$guard_y" "$old_guard_y"
        return 1
    fi

    # Find the largest Y value less than or greater to guard_y
    guard_y=$(cut -d: -f1 <<< "$column_info" | awk 'BEGIN{result=-1} {if($0 < '"$guard_y"') {result=$0} else exit} END{print result}')
    if [ "$guard_y" -le 0 ]; then
        guard_y=1
        modmap_vert "$column" "$guard_y" "$old_guard_y"
        return 1
    fi

    guard_y=$((guard_y + 1))

    # Modify the OG map with X's in the right places
    modmap_vert "$column" "$guard_y" "$old_guard_y"

    guard_move=move_right
    return 0
}

# $1 is the line to splice in
# $2 is low coord
# $3 is high coord
modmap_horiz() {
    local line
    line=$(cut -c-"$(($2 - 1))" <<< "$1" || echo -n)$(awk 'BEGIN{s = sprintf("%*s", '"$(($3 - $2 + 1))"', ""); gsub(".", "X", s); print s; exit}')$(cut -c"$(($3 + 1))"- <<< "$1")
    map=$(cat <(head -n"$((guard_y - 1))" <<< "$map") - <(tail -n"$(($(wc -l <<< "$map") - guard_y))" <<< "$map") <<< "$line")
}

# stdout is a new output map with the X's in the right places
# 1 is returned if the guard runs into the map edge.
move_right() {
    echo right
    # Get line for the guard's Y position
    local line
    local line_info
    local old_guard_x
    old_guard_x=$guard_x
    line=$(sed "$guard_y"'p;d' <<< "$map")
    line_info=$(grep -bo '#' <<< "$line")
    if [ "$?" != 0 ]; then
        guard_x=$(wc -L <<< "$line")
        modmap_horiz "$line" "$old_guard_x" "$guard_x"
        return 1
    fi

    # Find the smallest X value greater than or equal to guard_x
    guard_x=$(cut -d: -f1 <<< "$line_info" | awk '{if($0 >= '"$guard_x"') {print; exit}}')
    if [ -z "$guard_x" ]; then # I hope this is right lmao
        guard_x=$(wc -L <<< "$line")
        modmap_horiz "$line" "$old_guard_x" "$guard_x"
        return 1
    fi

    # Modify the OG map with X's in the right places
    modmap_horiz "$line" "$old_guard_x" "$guard_x"

    guard_move=move_down
    return 0
}

# $1 is the input map
# stdout is a new output map with the X's in the right places
# 1 is returned if the guard runs into the map edge.
move_down() {
    echo down
    # cut the map to the current column
    local column
    local column_info
    local old_guard_y
    old_guard_y=$guard_y
    column=$(cut -c "$guard_x" <<< "$map")
    column_info=$(grep -n '#' <<< "$column")
    # if [ "$?" != 0 ]; then
    #     guard_y=$(wc -l <<< "$map")
    #     modmap_vert "$column" "$old_guard_y" "$guard_y"
    #     return 1
    # fi

    # Find the largest Y value less than or greater to guard_y
    guard_y=$(cut -d: -f1 <<< "$column_info" | awk '{if($0 > '"$guard_y"') {print; exit}}')
    guard_y=$((guard_y - 1))
    if [ "$guard_y" -le 0 ]; then
        guard_y=$(wc -l <<< "$map")
        modmap_vert "$column" "$old_guard_y" "$guard_y"
        return 1
    fi

    # Modify the OG map with X's in the right places
    modmap_vert "$column" "$old_guard_y" "$guard_y"

    guard_move=move_left
    return 0
}

# stdout is a new output map with the X's in the right places
# 1 is returned if the guard runs into the map edge.
move_left() {
    echo left
    # Get line for the guard's Y position
    local line
    local line_info
    local old_guard_x
    old_guard_x=$guard_x
    line=$(sed "$guard_y"'p;d' <<< "$map")
    line_info=$(grep -bo '#' <<< "$line")
    # if [ "$?" != 0 ]; then
    #     guard_x=$(wc -L <<< "$line")
    #     modmap_horiz "$line" "$guard_x" "$old_guard_x"
    #     return 1
    # fi

    # Find the smallest X value greater than or equal to guard_x
    guard_x=$(cut -d: -f1 <<< "$line_info" | awk '{if(($0 + 1) < '"$guard_x"') {result=$0} else exit} END{print result}')
    echo "$guard_x"
    if [ -z "$guard_x" ]; then
        guard_x=1
        modmap_horiz "$line" "$guard_x" "$old_guard_x"
        return 1
    fi

    guard_x=$((guard_x + 2))

    # Modify the OG map with X's in the right places
    modmap_horiz "$line" "$guard_x" "$old_guard_x"

    guard_move=move_up
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

while "$guard_move"; do echo "$map"; echo; done
echo GUARD HAS EXITED THE FACILITY

echo "$map"
printf 'There are %s X'"'"'s.\n' "$(grep -o X <<< "$map" | wc -l)"

