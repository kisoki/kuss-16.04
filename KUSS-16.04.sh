#!/usr/bin/env bash

################################################################
# Name: Kisoki Ubuntu Security Script - 16.04 (KUSS-16.04.sh)
# Author: Nicholas Neal (ksksec) <nwneal@kisoki.com>
# Version: 0.1 (Alpha)
# Description: Script for checking and setting
#              security settings in Ubuntu 16.04 
#
################################################################

# root check
if [ "`whoami`" != "root" ]; then
	echo "You are running this script without root privileges."
	echo "It is recommended that you use root privileges to run this script."
	echo ""
	echo "if you want to continue, press 'Enter'..."
	echo "if you want to back out, press 'ctrl + c'"
	read -p "" somevar
fi 


# Used to load configuration
source ./kuss16.04-settings.sh

printf "${PRPT}KUSS 16.04 - V.0.1 (Alpha)\n"
printf "Kisoki Ubuntu Security Script 16.04\n\n"
printf "(2017) Kisoki Information Systems LLC - https://www.kisoki.com/${NOCT}\n\n"

# Run Settings Check
# echo "$LogTime uss: [$UserName] * $TFCName $TFCVersion - Install Log Started" >> $LogFile

printf "[${GRNT}INFO${NOCT}] Starting script. testing INFO color\n"
printf "[${YELT}WARNING${NOCT}] Starting script. testing WARNING color\n"
printf "[${REDT}CRITICAL${NOCT}] Starting script. testing CRITICAL color\n\n"

if [ "$KSK_LOGGING" = true ]; then

	if [ ! -e "$KSK_LOG_FILE" ]; then
		touch $KSK_LOG_FILE
	fi
	
	LogFile=$KSK_LOG_FILE
	printf "[${GRNT}INFO${NOCT}] Log file is located at: '${LogFile}'\n\n"
	
else
	printf "[${YELT}WARNING${NOCT}] Logging has been disabled.\n\n"
	LogFile="/dev/null"	
fi	

echo "$KSK_DATETIME kuss: [$KSK_RUN_USER] * - Starting KUSS 16.04 -" >> $LogFile

### Run APT 
if [ "$KSK_APT_UPDATE" = true ] || [ "$KSK_APT_UPGRADE" = true ]; then
	printf "[${GRNT}INFO${NOCT}] Running 'apt update'...\n"
	echo "$KSK_DATETIME kuss: [INFO] running 'apt update'." >> $LogFile
	apt update > /dev/null 2>&1
fi

if [ "$KSK_APT_UPGRADE" = true ]; then
	printf "[${GRNT}INFO${NOCT}] Running 'apt upgrade -y'...\n\n"
	echo "$KSK_DATETIME kuss: [INFO] running 'apt upgrade -y'." >> $LogFile
	apt upgrade -y > /dev/null 2>&1
fi
##################################################
### Module 1: Harden SSH
##################################################

if [ "$KSK_INSTALL_GAUTH" = true ]; then
	printf "[${GRNT}INFO${NOCT}] Checking to see if Google Authenticator is installed.\n"
	echo "$KSK_DATETIME kuss: [INFO] Checking to see if Google Authenticator is installed." >> $LogFile
	
	pass=true # used to see if package installation passed by rest of module.
	
	if [ ! -f /usr/bin/google-authenticator ]; then
		printf "\t[${YELT}WARNING${NOCT}] Google Authenticator is NOT installed.\n"
		echo "$KSK_DATETIME kuss: [WARNING] Google Authenticator is NOT installed." >> $LogFile
		if [ "$KSK_SET_MODE" = true ]; then
			printf "\t[${GRNT}INFO${NOCT}] Installing Google Authenticator.\n"
			echo "$KSK_DATETIME kuss: [INFO] Installing Google Authenticator." >> $LogFile
			
			apt install libpam-google-authenticator -y  > /dev/null 2>&1 || pass=false
			if [ "$pass" = true ]; then
				printf "\t\t[${GRNT}OK${NOCT}] Google Authenticator Successfully Installed.\n"
				echo "$KSK_DATETIME kuss: [OK] Google Authenticator Successfully Installed." >> $LogFile
			else
				printf "\t\t[${REDT}FAIL${NOCT}] There was an issue installing Google Authenticator.\n"
				echo "$KSK_DATETIME kuss: [FAIL] There was an issue installing Google Authenticator." >> $LogFile			
			fi
			 
		fi
	else 
		printf "\t[${GRNT}OK${NOCT}] Google Authenticator is installed.\n"
		echo "$KSK_DATETIME kuss: [OK] Google Authenticator is installed." >> $LogFile	
	fi
	
	if [ "$KSK_SET_MODE" = true ] && [ "$pass" = true ]; then
		if [ ! -e "$KSK_BACKUP/GAUTH" ]; then
			mkdir "$KSK_BACKUP/GAUTH"	
		fi 
		
		cp /etc/pam.d/sshd /etc/ssh/sshd_config "$KSK_BACKUP/GAUTH"
		
		if [ "$KSK_SETUP_2FA" = true ]; then
			printf "\t[${GRNT}INFO${NOCT}] Setting up 2FA with password+OTP or RSA Authentication.\n"
			echo "$KSK_DATETIME kuss: [INFO] Setting up 2FA with password+OTP or RSA Authentication." >> $LogFile
			
			# add google auth line to /etc/pam.d/sshd file
			sed -e "/@include common-password/a auth required pam_google_authenticator.so" /etc/pam.d/sshd > /tmp/sshd
			mv /tmp/sshd /etc/pam.d/sshd
			
			# change ChallengeResponseAuthentication to yes
			checkLine="`grep -c 'ChallengeResponseAuthentication' /etc/ssh/sshd_config`"
			if [ "$checkLine" -ge 1 ]; then
				sed -i '/ChallengeResponseAuthentication no/c\ChallengeResponseAuthentication yes' /etc/ssh/sshd_config			
			elif [ "$checkLine" -eq 0 ]; then 
				echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config
			fi

			printf "\t[${GRNT}INFO${NOCT}] 2FA set up, restarting SSH for changes to take effect.\n"
			echo "$KSK_DATETIME kuss: [INFO] 2FA set up, restarting SSH for changes to take effect." >> $LogFile
			
			# Restart SSH service for changes to take effect
			systemctl restart sshd.service
			
		elif [ "$KSK_SETUP_3FA" = true ]; then
			printf "\t[${GRNT}INFO${NOCT}] Setting up 3FA with RSA+password+OTP Authentication.\n"
			echo "$KSK_DATETIME kuss: [INFO] Setting up 3FA with RSA+password+OTP Authentication." >> $LogFile
			
			# add google auth line to /etc/pam.d/sshd file
			sed -e "/@include common-password/a auth required pam_google_authenticator.so" /etc/pam.d/sshd > /tmp/sshd
			mv /tmp/sshd /etc/pam.d/sshd
			
			# change ChallengeResponseAuthentication to yes
			checkLine="`grep -c 'ChallengeResponseAuthentication' /etc/ssh/sshd_config`"
			if [ "$checkLine" -ge 1 ]; then
				sed -i '/ChallengeResponseAuthentication no/c\ChallengeResponseAuthentication yes' /etc/ssh/sshd_config			
			elif [ "$checkLine" -eq 0 ]; then 
				echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config
			fi
			
			# change UsePAM to yes 
			checkLine="`grep -c 'UsePAM' /etc/ssh/sshd_config`"
			if [ "$checkLine" -eq 1 ]; then
				sed -i '/UsePAM no/c\UsePAM yes' /etc/ssh/sshd_config
			elif [ "$checkLine" -eq 0 ]; then
				echo "UsePAM yes" >> /etc/ssh/sshd_config
			fi
			
			# set AuthenticationMethods
			checkLine="`grep -c 'AuthenticationMethods' /etc/ssh/sshd_config`"
			if [ "$checkLine" -eq 1 ]; then
				sed '/AuthenticationMethods/s/.*/AuthenticationMethods publickey,password publickey,keyboard-interactive/' /etc/ssh/sshd_config > /tmp/sshd_config
				mv /tmp/sshd_config /etc/ssh/sshd_config
			else 
				echo "AuthenticationMethods publickey,password publickey,keyboard-interactive" >> /etc/ssh/sshd_config
			fi
			
			printf "\t[${GRNT}INFO${NOCT}] 3FA set up, restarting SSH for changes to take effect.\n"
			echo "$KSK_DATETIME kuss: [INFO] 3FA set up, restarting SSH for changes to take effect." >> $LogFile
						
			# Restart SSH service for changes to take effect
			systemctl restart sshd.service			
		else
			printf "\t[${GRNT}INFO${NOCT}] Google Authenticator was not set up.\n"
			echo "$KSK_DATETIME kuss: [INFO] Google Authenticator was not set up." >> $LogFile
		fi
	fi
	
	echo ""
fi

#######################

if [ "$KSK_SSH_DISABLE_ROOT" = true ]; then
	printf "[${GRNT}INFO${NOCT}] Checking if root login is disabled in SSH.\n"
	echo "$KSK_DATETIME kuss: [INFO] Checking if root login is disabled in SSH." >> $LogFile
	
	if [ "`grep -c 'PermitRootLogin no' /etc/ssh/sshd_config`" -lt 1 ]; then
		printf "\t[${YELT}WARNING${NOCT}] Root login is enabled in SSH.\n"
		echo "$KSK_DATETIME kuss: [WARNING]  Root login is enabled in SSH." >> $LogFile
		
		if [ "$KSK_SET_MODE" = true ]; then
			printf "\t[${GRNT}INFO${NOCT}] Disabling root login in SSH.\n"
			echo "$KSK_DATETIME kuss: [INFO] Disabling root login in SSH." >> $LogFile
			
			if [ ! -e "$KSK_BACKUP/DISABLE_ROOT_SSH" ]; then
				mkdir "$KSK_BACKUP/DISABLE_ROOT_SSH"
			fi
			
			cp /etc/ssh/sshd_config "$KSK_BACKUP/DISABLE_ROOT_SSH"
			if [ "`grep -c 'PermitRootLogin' /etc/ssh/sshd_config`" -ge 1 ]; then
				sed -i '/PermitRootLogin/c\PermitRootLogin no' /etc/ssh/sshd_config
			else
				echo "PermitRootLogin no" >> /etc/ssh/sshd_config
			fi
			
			printf "\t[${GRNT}OK${NOCT}] Root login is disabled in SSH. Restarting SSH...\n"
			echo "$KSK_DATETIME kuss: [OK]  Root login is disabled in SSH. Restarting SSH..." >> $LogFile	
			
			# Restart SSH service for changes to take effect
			systemctl restart sshd.service
		fi		
	else	
		printf "\t[${GRNT}OK${NOCT}] Root login is disabled in SSH.\n"
		echo "$KSK_DATETIME kuss: [OK]  Root login is disabled in SSH." >> $LogFile			
	fi
	
	echo ""
fi

#######################

if [ "$KSK_SSH_CHANGE_PORT" = true ]; then
	printf "[${GRNT}INFO${NOCT}] Checking which port SSH is set to listen on.\n"
	echo "$KSK_DATETIME kuss: [INFO] Checking which port SSH is set to listen on." >> $LogFile
	
	ssh_port="`grep Port /etc/ssh/sshd_config | awk '{print $2}'`"
	printf "\t[${GRNT}INFO${NOCT}] SSH is set to run on port '$ssh_port'.\n"
	echo "$KSK_DATETIME kuss: [INFO] SSH is set to run on port '$ssh_port'." >> $LogFile
	
	if [ "$KSK_SET_MODE" = true ] && [ "$ssh_port" != "$KSK_SSH_PORT" ]; then
		printf "\t[${GRNT}INFO${NOCT}] Setting SSH to run on port '$KSK_SSH_PORT'.\n"
		echo "$KSK_DATETIME kuss: [INFO] Setting SSH to run on port '$KSK_SSH_PORT'." >> $LogFile
	
		if [ ! -e "$KSK_BACKUP/SSH_CHANGE_PORT" ]; then
			mkdir "$KSK_BACKUP/SSH_CHANGE_PORT"
		fi
			
		cp /etc/ssh/sshd_config "$KSK_BACKUP/SSH_CHANGE_PORT"
		
		# change port
		sed -i "/Port $ssh_port/c\Port $KSK_SSH_PORT" /etc/ssh/sshd_config
		
		printf "\t[${GRNT}INFO${NOCT}] SSH is set to run on port '$KSK_SSH_PORT'. Restarting SSH...\n"
		echo "$KSK_DATETIME kuss: [INFO] SSH is set to run on port '$KSK_SSH_PORT'. Restarting SSH..." >> $LogFile
		
		# Restart SSH service for changes to take effect
		systemctl restart sshd.service
	fi
	echo ""
fi

#######################

if [ "$KSK_SSH_CHANGE_LISTEN_ADDR" = true ]; then
	printf "[${GRNT}INFO${NOCT}] Checking which address SSH is set to listen on.\n"
	echo "$KSK_DATETIME kuss: [INFO] Checking which address SSH is set to listen on." >> $LogFile
	count=`grep "^[^#;]" /etc/ssh/sshd_config | grep -c 'ListenAddress'`
	
	if [ "$count" -eq 1 ]; then
		commout=`grep "^[^#;]" /etc/ssh/sshd_config | grep 'ListenAddress' | awk '{print $2}'`
		printf "\t[${GRNT}OK${NOCT}] SSH is listening on '$commout'.\n"
		echo "$KSK_DATETIME kuss: [INFO] SSH is listening on '$commout'." >> $LogFile
	else
		printf "\t[${YELT}WARNING${NOCT}] SSH is listening on all addresses.\n"
		echo "$KSK_DATETIME kuss: [WARNING] SSH is listening on all addresses." >> $LogFile
		commout="0.0.0.0"
	fi
	
	if [ "$KSK_SET_MODE" = true ]; then
		printf "\t[${GRNT}INFO${NOCT}] Setting SSH listening address to '$KSK_SSH_LISTEN_ADDR'.\n"
		echo "$KSK_DATETIME kuss: [INFO] Setting SSH listening address to '$KSK_SSH_LISTEN_ADDR'." >> $LogFile	
		
		if [ ! -e "$KSK_BACKUP/SSH_CHANGE_ADDR" ]; then
			mkdir "$KSK_BACKUP/SSH_CHANGE_ADDR"
		fi
			
		cp /etc/ssh/sshd_config "$KSK_BACKUP/SSH_CHANGE_ADDR"
		
		# change listen address
		sed -i "/ListenAddress $commout/c\ListenAddress $KSK_SSH_LISTEN_ADDR" /etc/ssh/sshd_config
		
		printf "\t[${GRNT}OK${NOCT}] SSH listening address is now '$KSK_SSH_LISTEN_ADDR'. Restarting SSH...\n"
		echo "$KSK_DATETIME kuss: [INFO] SSH listening address is now '$KSK_SSH_LISTEN_ADDR'. Restarting SSH..." >> $LogFile
		
		# Restart SSH service for changes to take effect
		systemctl restart sshd.service
	fi
	
	echo ""
fi

#######################

if [ "$KSK_SSH_DISABLE_X11_FORWARDING" = true ]; then
	printf "[${GRNT}INFO${NOCT}] Checking if X11 Forwarding is disabled in SSH.\n"
	echo "$KSK_DATETIME kuss: [INFO] Checking if X11 Forwarding is disabled in SSH." >> $LogFile
	
	echo ""
fi

#######################

if [ "$KSK_SSH_SET_VERBOSE_LOG" = true ]; then
	printf "[${GRNT}INFO${NOCT}] Checking to see if logging is set to verbose in SSH.\n"
	echo "$KSK_DATETIME kuss: [INFO] Checking to see if logging is set to verbose in SSH." >> $LogFile
	
	echo ""
fi

#######################

if [ "$KSK_SSH_CHANGE_GRACE_TIME" = true ]; then
	printf "[${GRNT}INFO${NOCT}] Checking grace time for new SSH connections.\n"
	echo "$KSK_DATETIME kuss: [INFO] Checking grace time for new SSH connections." >> $LogFile
	
	echo ""
fi

#######################

if [ "$KSK_SSH_SET_LOGIN_GROUP" = true ]; then
	printf "[${GRNT}INFO${NOCT}] Checking if a login group is set for SSH.\n"
	echo "$KSK_DATETIME kuss: [INFO] Checking if a login group is set for SSH." >> $LogFile
	
	echo ""
fi


