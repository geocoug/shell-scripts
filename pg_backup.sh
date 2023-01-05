#!/bin/bash

################################################################################
# Module ..... pg_backup.sh                                                    #
# Desc ....... Postgres backup script                                          #
#              Creates tarballs on /Users/cgrant/OneDrive/Backups/postgres     #
#              Set maximum number of allowed backups using the MAX_BACKUPS     #
#                variable. The oldest backup(s) which exceed the MAX_BACKUPS   #
#                count will be removed.                                        #
#              If the script is run as postgres user, remove the DB_PASS       #
#                and "export PGPASSWORD=$DB_PASS;" codes                       #
################################################################################

DB_PASS=`head -n 1 $HOME/bin/pg_pass`
MAX_BACKUPS=30

# Capture starting timestamp
TIMESLOT=`date +%Y_%m_%d.%H_%M`
printf "[$TIMESLOT] START ...................... pg_backup\n"
printf "[$TIMESLOT] TIMESLOT ................... $TIMESLOT\n"

# Location to place local backup (before copying to remote mount point)
BACKUP_DIR=$HOME/iCloud/Backups/postgres
printf "[$TIMESLOT] BACKUP_DIR ................. $BACKUP_DIR\n"

# cd to the backup dir 
cd $BACKUP_DIR

# Dump the globals to a backup file
printf "[$TIMESLOT] Dumping globals to ......... $TIMESLOT.globals.sql\n"
printf "[$TIMESLOT]\n"
/opt/homebrew/bin/pg_dumpall -g > $TIMESLOT.globals.sql

# Get a list of all of the databases
DATABASES=`export PGPASSWORD=$DB_PASS; /opt/homebrew/bin/psql -q -l -t | awk {'print $1'} | sort | grep -v "|\|^template"`

# Dump each database
for DATABASE in $DATABASES; do
    printf "[$TIMESLOT] Processing db .............. $DATABASE\n"
    TIMEINFO=`date '+%T'`
    export PGPASSWORD=$DB_PASS; /opt/homebrew/bin/pg_dump -Fc $DATABASE > $TIMESLOT.$DATABASE.pgdb
    printf "[$TIMESLOT] Backup complete ............ at $TIMEINFO\n"
    printf "[$TIMESLOT] Temp dump created as ....... $TIMESLOT.$DATABASE.pgdb\n"
    printf "[$TIMESLOT]\n"
done

# Tar-up the globals and database dumps
printf "[$TIMESLOT] Creating tarball ........... $TIMESLOT.tar.gz\n"
tar -zcvf $TIMESLOT.tar.gz $TIMESLOT.*
printf "[$TIMESLOT]\n"

# If the tarball exists...
if [ ! -f $TIMESLOT.tar.gz ]; then
    printf "[$TIMESLOT] ERROR: Unable to create the tarball\n"
else
    TARBALL_ATTRIBUTES=`ls -l --color='never' $TIMESLOT.tar.gz`
    printf "[$TIMESLOT] Tarball created ............ $TARBALL_ATTRIBUTES\n"

    # Remove the tmp backup files
    printf "[$TIMESLOT] Removing tmp files ......... *.pgdb and *.sql\n"
    rm *.pgdb
    rm *.sql
fi

# Count number of backups that exist
BACKUP_COUNT="$(find . -name '*.tar.gz' | wc -l | xargs)"
# Check if the number of backups exceeds max number of allowed backups
if (( $BACKUP_COUNT > $MAX_BACKUPS )); then
    printf "[$TIMESLOT]\n"
    NUM_EXCEEDS=$(( $BACKUP_COUNT - $MAX_BACKUPS ))
    OLDEST="$(find . -name '*.tar.gz' | ls -tr1 | head -n$NUM_EXCEEDS)"
    printf "[$TIMESLOT] Exceeded maximum number of allowed backups ($MAX_BACKUPS)\n"
    printf "[$TIMESLOT] Removing oldest backup(s)\n"
    printf "$OLDEST\n"
    rm $OLDEST
fi

# Write "END", and cause an extra line break to separate nightly messages
ENDTIME=`date +%Y_%m_%d.%H_%M`
printf "[$TIMESLOT] END ........................ pg_backup at $ENDTIME\n\n"
