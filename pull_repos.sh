#!/bin/bash

################################################################################
# Module ..... pull_repos.sh                                                   #
# Desc ....... Pull Git repos for every repo in a provided path.               #
################################################################################

TIMESLOT=`date +%Y_%m_%d.%H_%M`
printf "[$TIMESLOT] START ...................... pull_repos\n"

START_DIRECTORY=`pwd`
printf "[$TIMESLOT] START_DIRECTORY ............ $START_DIRECTORY\n"
printf "[$TIMESLOT] ............................\n"

for SUBDIR in $START_DIRECTORY/*/;
do
    printf "[$TIMESLOT] CHECKING ................... ${SUBDIR%*/}\n"
    cd ${SUBDIR%*/}
    STATUS=`git status`
    # If not a git repo then skip.
    if grep -q "fatal: not a git repository" <<< "$STATUS"; then
        continue
    # If the status is not fatal, determine branch name and pull.
    else
        BRANCH=`grep -q "On branch " <<< "$STATUS"`
        git pull origin "${BRANCH/On branch /""}"
    fi
    cd ..
    printf "[$TIMESLOT] ............................\n"
done;

ENDTIME=`date +%Y_%m_%d.%H_%M`
printf "[$TIMESLOT] ............................\n"
printf "[$TIMESLOT] END ........................ $ENDTIME\n\n"
