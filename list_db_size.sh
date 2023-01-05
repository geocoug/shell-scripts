#!/bin/bash

################################################################################
# Module .... list_db_size.sh                                                  #
# Desc ...... list size of selected database within one backup .tar.gz file    #
################################################################################


RUN_TIME=`date +'%m/%d/%Y %H:%M:%S (%Z)'`

printf "list_db_size.sh | Run time: $RUN_TIME\n"
printf "\n"

ARGC=$#

if [ $ARGC -ne 2 ]; then
    printf "Usage: list_db_size.sh  {ARCHIVE} {DBNAME}\n"
    printf "Ex:    list_db_size.sh  $HOME/backups/postgres/2023_01_01.09_01.tar.gz personal\n"
    printf "\n"
    exit
fi

ARCHIVE=$1                                  # ex: $HOME/backups/postgres/2023_01_01.09_01.tar.gz
DB_NAME=$2                                  # ex: personal
DIRNAME=$(dirname ${ARCHIVE})               # ex: $HOME/backups/postgres
BASENAME=$(basename ${ARCHIVE})             # ex: 2023_01_01.09_01.tar.gz
PGDB_NAME=${BASENAME/tar.gz/$DB_NAME.pgdb}  # ex: 2023_01_01.09_01.personal.pgdb

printf "ARCHIVE ...... $ARCHIVE\n"
printf "DB_NAME ...... $DB_NAME\n"
printf "DIRNAME ...... $DIRNAME\n"
printf "BASENAME ..... $BASENAME\n"
printf "PGDB_NAME .... $PGDB_NAME\n"
printf "\n"

printf "Searching $ARCHIVE for $PGDB_NAME...\n"
PGDB_DETAILS=`tar -tzvf $ARCHIVE $PGDB_NAME`
printf "Found: $PGDB_DETAILS\n"
printf "\n"
