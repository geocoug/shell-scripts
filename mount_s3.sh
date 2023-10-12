#!/bin/bash

################################################################################
# Module .... mount_s3.sh                                                      #
# Desc ...... mount S3 bucket to local filesystem                              #
# Req ....... The following packages must be installed:                        #
#               s3fs                                                           #
#             Then, enable "user_allow_other" in "/etc/fuse.conf"              #
# Comment ... Consider adding the following to /etc/fstab:                     #
#             s3fs#$BUCKET_NAME $MOUNT_PATH fuse _netdev,allow_other,use_cache=/tmp,uid=1001,mp_umask=002,multireq_max=5,use_path_request_style,url=https://sfo3.digitaloceanspaces.com,passwd_file=$S3FS_PASSWD_FILE 0 0
################################################################################

# Path to mount point. The bucket name will be appended to this path.
# If the path does not exist it will be created.
# The mount point should be within the user's home directory, otherwise 
# this script will fail as it does not run as root.
MOUNT_PATH=$HOME/mnt/s3

# Password file should contain a single line in the following format:
#    ACCESS_KEY_ID:SECRET_ACCESS_KEY
S3FS_PASSWD_FILE=$HOME/.passwd_s3fs

# Capture starting timestamp
TIMESTAMP=`date +%Y_%m_%d.%H_%M`

printf "mount_s3.sh | Run time: $TIMESTAMP\n\n"

# Check for required arguments
ARGC=$#
if [ $ARGC -ne 1 ]; then
    printf "Usage: mount_s3.sh {BUCKET_NAME}\n"
    printf "Ex:    mount_s3.sh my-bucket\n"
    printf "\n"
    exit
fi

# Get bucket name from command line
BUCKET_NAME=$1

# Create dynamic mount path based on bucket name
MOUNT_PATH=$MOUNT_PATH/$BUCKET_NAME

# Check that S3FS_PASSWD_FILE exists
if [ ! -f $S3FS_PASSWD_FILE ]; then
    printf "[$TIMESTAMP] ERROR: $S3FS_PASSWD_FILE does not exist.\n"
    printf "\n"
    exit
fi

# Check that the contents of S3FS_PASSWD_FILE are in the correct format
PASSWD_FILE_CONTENTS=`cat $S3FS_PASSWD_FILE`
if [[ $PASSWD_FILE_CONTENTS != *:* ]]; then
    printf "[$TIMESTAMP] ERROR: $S3FS_PASSWD_FILE is not in the correct format.\n"
    printf "[$TIMESTAMP]        Contents should be in the format: ACCESS_KEY_ID:SECRET_ACCESS_KEY\n"
    printf "\n"
    exit
fi

# Check that s3fs is installed
S3FS_INSTALLED=`which s3fs`
if [ -z $S3FS_INSTALLED ]; then
    printf "[$TIMESTAMP] ERROR: s3fs is not installed.\n"
    printf "\n"
    exit
fi

# Check that mount path exists. If not, create it
if [ ! -d $MOUNT_PATH ]; then
    printf "[$TIMESTAMP] Creating $MOUNT_PATH\n"
    mkdir -p $MOUNT_PATH
fi

# Check that mount path is empty
if [ "$(ls -A $MOUNT_PATH)" ]; then
    printf "[$TIMESTAMP] INFO: $MOUNT_PATH is not empty. Skipping mount operation.\n"
    printf "\n"
    exit
fi

# Mount the bucket
printf "[$TIMESTAMP] Mounting ............. $BUCKET_NAME -> $MOUNT_PATH\n"
printf "[$TIMESTAMP] S3 credentials ....... $S3FS_PASSWD_FILE\n"

s3fs $BUCKET_NAME $MOUNT_PATH -o passwd_file=$S3FS_PASSWD_FILE -o allow_other -o use_cache=/tmp -o uid=1001 -o mp_umask=002 -o multireq_max=5 -o use_path_request_style -o url=https://sfo3.digitaloceanspaces.com -o nonempty

# Show mount details
printf "[$TIMESTAMP] Mount complete\n"
df -h | grep $BUCKET_NAME

# Include a few helpful commands
printf "[$TIMESTAMP]\n"
printf "[$TIMESTAMP] To test .............. ls $MOUNT_PATH\n"
printf "[$TIMESTAMP] To unmount ........... umount $MOUNT_PATH\n"
