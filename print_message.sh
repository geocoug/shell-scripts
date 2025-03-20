#!/usr/bin/env bash

#################################################################################
# Module ..... print_message.sh                                                 #
# Desc ....... Example of a function to print a formatted message with spacing. #
#################################################################################


print_message() {
    local fixed_column=52
    local timeslot=$(date +'%Y-%m-%d %T')

    [[ $# -ne 2 ]] && { printf "Usage: print_message <title> <detail>\n"; return 1; }

    local title="$1"
    local detail="$2"

    # Truncate title if too long
    if (( ${#title} > fixed_column )); then
        printf "[%s] ERROR: Title exceeds width limit: %s\n" "$timeslot" "$title"
        return 1
    fi

    # Align detail text
    local spacing=$((fixed_column - ${#title}))
    local dots=$(printf ".%.0s" $(seq 1 $spacing))

    printf "[%s] %s%s %s\n" "$timeslot" "$title" "$dots" "$detail"
}

print_message "START" "$(basename $0)"
print_message "NOTHING" ""
print_message "Too" "Many" "Arguments"
print_message "" ""
sleep 2
print_message "SOMETHING REALLY REALLY REALLY REALLY REALLY REALLY LONG" "SOMETHING SHORT"
print_message "END" "$(basename $0)"

