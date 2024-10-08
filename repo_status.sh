#!/bin/bash

################################################################################
# Module ..... repo_status.sh                                                  #
# Desc ....... Check the Git status for every subdirectory in a provided path. #
################################################################################

TIMESLOT=$(date +%Y_%m_%d.%H_%M)
printf "[$TIMESLOT] START ...................... pull_repos\n"

START_DIRECTORY=$(pwd)
printf "[$TIMESLOT] START_DIRECTORY ............ $START_DIRECTORY\n"
printf "[$TIMESLOT] ............................\n"

# Use an array to handle directories properly
shopt -s nullglob
directories=("$START_DIRECTORY"/*/)

for SUBDIR in "${directories[@]}"; do
    # Skip over directories containing the names "_archive" and "gist"
    # since those are not standard git repositories
    if [[ "$SUBDIR" =~ .*"_archive".* ]] || [[ "$SUBDIR" =~ .*"gist".* ]]; then
        continue
    fi
    printf "[$TIMESLOT] CHECKING ................... ${SUBDIR%*/}\n"
    cd "${SUBDIR%*/}" || continue
    STATUS=$(git status)
    # If the status returns as a clean tree then don't write anything to the console.
    if grep -q "working tree clean" <<< "$STATUS"; then
        cd ..
        continue
    # If the status returns anything besides clean, write the status to the console.
    else
        printf "$STATUS\n"
    fi
    cd ..
    printf "[$TIMESLOT] ............................\n"
done

ENDTIME=$(date +%Y_%m_%d.%H_%M)
printf "[$TIMESLOT] ............................\n"
printf "[$TIMESLOT] END ........................ $ENDTIME\n\n"