#!/bin/bash

################################################################################
# Module ..... pg_restore.sh                                                   #
# Desc ....... Restore Postgres backups.                                       #
#              Restores all *.pgdb files in the current directory              # 
#              to the database specified in the file name.                     #
#              If no *.pgdb files are found in the current directory,          #
#              this script will also extract *.pgdb files from *.tar.gz files. #
#              If any *.pgdb files are found in the *.tar.gz files,            #
#              those will be extracted and restored.                           #
#              The script will first check for *.pgdb files in the directory,  #
#              then for *.tar.gz files.                                        #
#              Note that the *globals.sql file is not restored by this script. #
#                                                                              #
#              The file name must be in the format                             #
#                YYYY_MM_DD.HH_MM.<database_name>.pgdb                         #
#              This script is designed to work with output from                #
#              the ./pg_backup.sh script.                                      #
#                                                                              #
#              The following variables must be set in order to run this script #
#              - PG_HOST: the host name of the PostgreSQL server               #
#              - PG_PORT: the port number of the PostgreSQL server             #
#              - PG_USER: the user name of the PostgreSQL user                 #
#              - PG_PASSWORD: the password of the PostgreSQL user              #
#                                                                              #
#              You can set these variables in the .env file in the same        #
#                directory as this script. Alternatively, you can set them in  #
#                the environment before running this script.                   #
#              Example of setting the variables in the environment:            #
#                PG_HOST=localhost PG_PORT=5432 PG_USER=postgres \             #
#                   PG_PASSWORD=postgres; ./pg_restore.sh <backup_dir>         #   
#                                                                              #
# Example .... 1) Using .env files                                             #
#                    ./pg_restore.sh -v <backup_dir>                           #
#              2) Using environment variables                                  #
#                   PG_HOST=localhost PG_PORT=5432 PG_USER=postgres \          #
#                   PG_PASSWORD=postgres; ./pg_restore.sh -v <backup_dir>      #
################################################################################

# Script name
SCRIPT=$(basename $0)
# Capture starting timestamp
TIMESLOT=`date +%Y_%m_%d.%H_%M`

function header() {
    # Script header information.
    printf "$SCRIPT | Run time: $TIMESLOT\n"
    printf "Restore *.pgdb files.\n"
    printf "\n"
}

function help() {
    # Show help documentation.
    header
    printf "Syntax: $SCRIPT [-v|h]%b {BACKUP_DIR}\n"
    printf "Options:%b\n"
    printf "  -v    Run the script in verbose mode.%b\n"
    printf "  -h    Print this help.%b\n"
    printf "Example: $SCRIPT -v ./backups\n"
    printf "\n"
    exit 0
}

# Argument parser.
#  $# = number of function arguments.
#  $* = all arguments.
#  $@ = all arguments, starting from 1.
#  $1 = first argument.
if [ $# -gt 2 ]
then
    printf "Unexpected arguments: $*\n"
    printf "\n"
    help
else
    if [ $# -gt 0 ]
    then
        case "$1" in
            -h) help;;
            -v) VERBOSE=true;;
            *) help;;
        esac
    fi 
fi

# Check if VERBOSE is set
if [ -z "$VERBOSE" ]; then
    VERBOSE=false
fi

# Capture starting timestamp
printf "[$TIMESLOT] START ...................... $(basename $0)\n"

# Check if the required variables are set
if [ -z "$PG_HOST" ]; then
    printf "[$TIMESLOT] ............................ Error: PG_HOST is not set\n"
    exit 1
fi
if [ -z "$PG_PORT" ]; then
    printf "[$TIMESLOT] ............................ Error: PG_PORT is not set\n"
    exit 1
fi
if [ -z "$PG_USER" ]; then
    printf "[$TIMESLOT] ............................ Error: PG_USER is not set\n"
    exit 1
fi
if [ -z "$PG_PASSWORD" ]; then
    printf "[$TIMESLOT] ............................ Error: PG_PASSWORD is not set\n"
    exit 1
fi
# Check if a backup directory was specified
if [ -z "$1" ]; then
    printf "[$TIMESLOT] ............................ Error: no backup directory specified\n"
    exit 1
fi
# Check if the backup directory exists
if [ ! -d "$1" ]; then
    printf "[$TIMESLOT] ............................ Error: backup directory '$1' does not exist\n"
    exit 1
fi

# Check if the directory contains any *.pgdb files. If not, check if
# there is a *.tar.gz file and ask the user if they want to extract
# the *.pgdb files from the *.tar.gz file.
if [ -z "$(ls -A *.pgdb 2>/dev/null)" ]; then
    if [ -z "$(ls -A *.tar.gz 2>/dev/null)" ]; then
        printf "[$TIMESLOT] ............................ Error: no *.pgdb or *.tar.gz files found in the current directory\n"
        exit 1
    else
        printf "[$TIMESLOT] ............................ No *.pgdb files found in the directory '$1'\n"
        printf "[$TIMESLOT] ............................ Found the following *.tar.gz files:\n"
        ls -1 *.tar.gz
        printf "[$TIMESLOT] ............................ Do you want to extract *.pgdb files from the *.tar.gz file(s)?\n"
        select yn in "Yes" "No"; do
            case $yn in
                Yes ) break;;
                No ) exit;;
            esac
        done
        for file in *.tar.gz; do
            printf "[$TIMESLOT] ............................ Extracting *.pgdb files from file '$file'\n"
            tar -xvf "$file" "*.pgdb"
        done
        # Check if the directory contains any *.pgdb files
        if [ -z "$(ls -A *.pgdb 2>/dev/null)" ]; then
            printf "[$TIMESLOT] ............................ Error: no *.pgdb files found in file '$file'\n"
            exit 1
        fi
    fi
fi

# Iterate over all *.pgdb files in the current directory
for file in *.pgdb; do
    printf "[$TIMESLOT] ............................ Processing file '$file'\n"
    # Extract the database name from the file name
    database=$(echo "$file" | sed -E 's/^[0-9]{4}_[0-9]{2}_[0-9]{2}\.[0-9]{2}_[0-9]{2}\.([a-zA-Z0-9_]+)\.pgdb$/\1/')
    if [ -z "$database" ]; then
        printf "[$TIMESLOT] ............................ Error: could not extract database name from file name '$file'\n"
        exit 1
    fi

    # Steps for pretty pretty log messages
    # Get the number of characters in the database name
    db_length=${#database}
    # Substract the number of characters in the database name from 28
    dot_length=$((27-$db_length))
    # Create a string of dots to format log messages
    dots="$(for i in $(seq 1 $dot_length) ; do printf '.'; done)"

    # Restore the database
    printf "[$TIMESLOT] $database $dots Restoring database\n"
    # If verbose mode then enable verbose pg_restore
    pg_verbose=""
    if [ "$VERBOSE" = true ]; then
        pg_verbose="--verbose"
    fi
    # Run the restore command
    # Set the PGPASSWORD environment variable to avoid the password prompt
    PGPASSWORD="$PG_PASSWORD" pg_restore --host="$PG_HOST" --port="$PG_PORT" --username="$PG_USER" --dbname="postgres" --no-password --clean --create $pg_verbose "$file"
done

printf "[$TIMESLOT] ............................ Done at $(date +%Y-%m-%d %H:%M:%S)\n"
