#!/bin/bash

################################################################################
# Desc ...... Mount Windows network shares with inbound user's credentials     #
################################################################################

function mount_share
    {
    # ex: myShare
    SHARE_IP=$1     # ex: ip
    MOUNT_NAME=$2   # ex: Home
    SHARE_NAME=$3   # ex: home/cgrant

    # ex1: /home/cgrant/mnt/c0000-c0749
    # ex2: /home/cgrant/mnt/Home
    MOUNT_POINT=/home/$USER_NAME/mnt/$MOUNT_NAME

    # if already mounted, rc = 0
    grep -qs $MOUNT_POINT /proc/mounts
    RESULT=$?

    if [ $RESULT -eq 0 ]; then
        # skip - already mounted
        printf "[`date +'%m-%d-%Y %T'`] [$SCRIPT_NAME] Mounting $MOUNT_POINT with $USER_NAME credentials (skipping - already mounted)\n"
    else
        # Mount
        printf "[`date +'%m-%d-%Y %T'`] [$SCRIPT_NAME] Mounting $MOUNT_POINT with $USER_NAME credentials\n"

        # Create mount point directory (if does not exist)
        if [ ! -d $MOUNT_POINT ]; then
            mkdir -p $MOUNT_POINT
        fi

        # Mount the share
        if [ $MOUNT_NAME == "Home" ]; then
            mount -t cifs //$SHARE_IP/$SHARE_NAME $MOUNT_POINT -o username=$WIN_USER,password="$WIN_PW",uid=$USER_ID,cifsacl
        else
            #mount -t cifs //$SHARE_IP/$SHARE_NAME $MOUNT_POINT -o username=$WIN_USER,password="$WIN_PW",uid=$USER_ID,vers=1.0
            mount -t cifs //$SHARE_IP/$SHARE_NAME $MOUNT_POINT -o username=$WIN_USER,password="$WIN_PW",uid=$USER_ID
        fi
    fi
    }


################################################################################
# main                                                                         #
################################################################################

# ex: mount_shares.sh
SCRIPT_NAME=`basename $0`

printf "[`date +'%m-%d-%Y %T'`] [$SCRIPT_NAME] mount_shares.sh. Current time: `date +'%m/%d/%Y %T'`\n"

# Must run as root
if [ $(id -u) != "0" ]; then
    printf "ERROR: Must run as root.\n"
    printf "\n"
    exit
fi

# Must have exactly 3 args
ARGC=$#
if [ $ARGC != 3 ]; then
    printf "Usage: mount_shares.sh {username} {win_user} {\"win_pw\"}\n"
    printf "ex:    mount_shares.sh cgrant cgrant \"<secret>\"\n"
    printf "\n"
    exit
fi

# ex: cgrant
USER_NAME=$1

# ex: cgrant
WIN_USER=$2

# ex: "<secret>"
WIN_PW=$3

# ex: 1001
# mount with this uid and it's credentials
USER_ID=`id -u $USER_NAME`

printf "[`date +'%m-%d-%Y %T'`] [$SCRIPT_NAME] USER_NAME: $USER_NAME ($USER_ID)\n"

# Mount project shares
mount_share 192.168.1.1 myShare       myShare
mount_share 192.168.1.1 Home          home$/$WIN_USER

# Display user mounts (should be > 0)
USER_MOUNT_COUNT=`df -h | grep /home/$USER_NAME/mnt | wc -l`
if [[ $USER_MOUNT_COUNT -eq 0 ]]; then
    printf "$USER_NAME Mounted ($USER_MOUNT_COUNT)\n"
else
    printf "$USER_NAME Mounted ($USER_MOUNT_COUNT):\n"
    df -h | grep /home/$USER_NAME/mnt
fi
