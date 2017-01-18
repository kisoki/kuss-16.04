#!/usr/bin/env bash

# kuss16.04-settings.sh

#########################
### START UP
#########################

# Load colors
REDT='\033[0;31m' # add red to text
GRNT='\033[0;32m' # add green to text
YELT='\033[1;33m' # add yellow to text
BLUT='\033[0;34m' # add blue to text
PRPT='\033[1;35m' # add light puple to text
NOCT='\033[0m' # add no color to text

# RUN settings
# if false, run in check only mode
KSK_SET_MODE=false

# run update commands
KSK_APT_UPDATE=false
KSK_APT_UPGRADE=false # if upgrade is true, update will also run

# Sets running user
KSK_RUN_USER=$(whoami)

# set directory where KUSS will write config files
KSK_RUN_DIR="/tmp/kuss-16.04"

# sets date and datetime
KSK_DATE=$(date '+%Y-%m-%d')
KSK_DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# KSK_LOG_FILE (/location/to/log/to.log)
if [ ! -e "$KSK_RUN_DIR" ]; then
	mkdir $KSK_RUN_DIR
fi

KSK_LOGGING=true
KSK_LOG_FILE="$KSK_RUN_DIR/kuss-16.04_$KSK_DATE.log"

# Set location where config files will be backed up.
KSK_BACKUP="$KSK_RUN_DIR/backups"
if [ ! -e "$KSK_BACKUP" ]; then
	mkdir $KSK_BACKUP
fi

##################################################
### Module 1: Harden SSH
##################################################

### Install OTP and RSA keys (Google Authenticator) ###
KSK_INSTALL_GAUTH=false

# This will require password and OTP or RSA for authentication 
KSK_SETUP_2FA=false

# This will require RSA, password, and OTP for authentication
KSK_SETUP_3FA=false

# load OTP files, OTP files should be stored in a tar.gz format.
# file structure should be like so:
# 		./keys/<username>/OTP/.google_authenticator
#		./keys/<username>/RSA/id_rsa.pub
# these will be loaded in when users are created.
KSK_LOAD_OTP=false
KSK_LOAD_RSA=false
KSK_KEY_FILES="./keys.tar.gz"

### used to disable root login in SSH
KSK_SSH_DISABLE_ROOT=false

### change port that SSH uses
KSK_SSH_CHANGE_PORT=false
KSK_SSH_PORT_VALUE="22"

### change address that SSH will listen on
KSK_SSH_CHANGE_LISTEN_ADDR=false
KSK_SSH_LISTEN_ADDR=""

### turn off X11 forwarding in SSH
KSK_SSH_X11_FORWARDING=false

### turn on verbose logging in SSH
KSK_SSH_VERBOSE_LOG=false

### set grace time for SSH connections being established
KSK_SSH_CHANGE_GRACE_TIME=false
KSK_SSH_GRACE_TIME="60"

### set group for allowed SSH logins
KSK_SSH_SET_LOGIN_GROUP=false
KSK_SSH_LOGIN_GROUP="sshlogin"
KSK_SSH_LOGIN_GROUP_USERS="<username>,<username>" # This will set who should have access to this group when users are added.
