#!/bin/bash
# Sinusbot Installer by Philipp Eßwein - DAThosting.eu philipp.esswein@dathosting.eu

# Simple Error Exit

set -o history -o histexpand -e

# Vars

USERADD=$(which useradd)
GROUPADD=$(which groupadd) 
MACHINE=$(uname -m)
ipaddress=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')
Instversion="1.3.6"

# Functions

function greenMessage {
    echo -e "\\033[32;1m${@}\033[0m"
}

function magentaMessage {
    echo -e "\\033[35;1m${@}\033[0m"
}

function cyanMessage {
    echo -e "\\033[36;1m${@}\033[0m"
}

function redMessage {
    echo -e "\\033[31;1m${@}\033[0m"
}

function yellowMessage {
	echo -e "\\033[33;1m${@}\033[0m"
}

function errorQuit {
    errorExit 'Exit now!'
}

function errorExit {
    redMessage "${@}"
    exit 0
}

function errorContinue {
    redMessage "Invalid option."
    return
}

function makeDir {
    if [ -n "$1" ] && [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

function checkInstall {
    if [ "$(dpkg-query -s "$1" 2>/dev/null)" == "" ]; then
        greenMessage "Installing package $1"
        apt-get install -y "$1" 2>/dev/null
    fi
}

# Checking Installer version

#checkInstall wget
#showversion=$(wget https://sinusbot-installer.de/version -q -O -)
#if [ $(wget https://sinusbot-installer.de/version -q -O -) == "$Instversion" ]; then
#	greenMessage "Installer is uptodate"
#else
#	errorExit 'Please download a newer installer version! Latest version is $showversion!'
#fi	

# Must be root. Checking...

if [ "$(id -u)" != "0" ]; then
    cyanMessage "Change to root account required"
    su root
	
	fi 
	
if [ "$(id -u)" != "0" ]; then
    errorExit "Still not root, aborting" 
	
	fi

# Start installer
	
if [ -f /etc/debian_version ] || [ -f /etc/centos-release ]; then
    greenMessage "This is the automatic installer for latest Sinusbot. USE AT YOUR OWN RISK"!
	sleep 1
    cyanMessage "You can choose between installing, upgrading and removing the Sinusbot."
	sleep 1
    redMessage "Installer by Philipp Esswein | DAThosting.eu - Your game-/voiceserver hoster (only german)."
	sleep 1
	magentaMessage "Please rate this script at: https://forum.sinusbot.com/resources/sinusbot-installer-script.58/"
	sleep 1
	yellowMessage "You're using Installer $Instversion"
	
# What should be done?

	redMessage "What should the Installer do?"
	
	OPTIONS=("Install" "Update" "Remove" "PW Reset" "Quit")
	select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2|3|4 ) break;;
            5 ) errorQuit;;
            *) errorContinue;;
        esac
    done
	
	if [ "$OPTION" == "Install" ]; then
		INSTALL="Inst"
	elif [ "$OPTION" == "Update" ]; then
		INSTALL="Updt"
	elif [ "$OPTION" == "Remove" ]; then
		INSTALL="Rem"	
	elif [ "$OPTION" == "PW Reset" ]; then
		INSTALL="Res"

	fi
	
# PW Reset

if [ "$INSTALL" == "Res" ]; then
	yellowMessage "Automatic usage or own directories?"
		
		OPTIONS=("Automatic" "Own path" "Quit")
		select OPTION in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2 ) break;;
				3 ) errorQuit;;
				*) errorContinue;;
			esac
		done
		
		if [ "$OPTION" == "Automatic" ]; then
			LOCATION=/opt/sinusbot			
			
		elif [ "$OPTION" == "Own path" ]; then
			yellowMessage "Enter location where the bot should be installed/updated/removed. Like /opt/sinusbot. Include the / at first position and none at the end"!
		
			LOCATION=""
				while [[ ! -d $LOCATION ]]; do
					read -p -r "Location [/opt/sinusbot]: " LOCATION
					if [ "$INSTALL" != "Inst" ] && [ ! -d $LOCATION ]; then
						redMessage "Directory not found, try again"!
						fi
				done
			
			greenMessage "Your directory is $LOCATION."
			
			OPTIONS=("Yes" "No, change it" "Quit")
				select OPTION in "${OPTIONS[@]}"; do
					case "$REPLY" in
						1|2 ) break;;
						3 ) errorQuit;;
						*) errorContinue;;
					esac
				done
				
				if [ "$OPTION" == "No, change it" ]; then
					LOCATION=""
					while [[ ! -d $LOCATION ]]; do
						read -p "Location [/opt/sinusbot]: " LOCATION
						if [ "$INSTALL" != "Inst" ] && [ ! -d $LOCATION ]; then
							redMessage "Directory not found, try again"!
							fi
					done
					
					greenMessage "Your directory is $LOCATION."
					
					fi
				
			fi
			
			LOCATIONex=$LOCATION/sinusbot
			
	if [ ! -f $LOCATION/sinusbot ]; then
		errorExit "Sinusbot wasn't found at $LOCATION. Exiting script."
		fi
			
	PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
	SINUSBOTUSER=$(ls -ld $LOCATION | awk '{print $3}')
	
	greenMessage "Please login to your sinusbot webinterface as admin and "$PW
	yellowMessage "After that change your password under user accounts->admin. The script restart the bot with init.d or systemd."
	
	if [ -f /lib/systemd/system/sinusbot.service ]; then
		service sinusbot stop
		
		fi
		
	if [ -f /etc/init.d/sinusbot ]; then
		/etc/init.d/sinusbot stop
		
		fi
	
	log="/tmp/sinusbot.log"
	match="USER-PATCH [admin] (admin) OK"

	su -c "$LOCATIONex --pwreset=$PW" $SINUSBOTUSER > "$log" 2>&1 &
	sleep 3

	while true
	do
		echo -ne '(Waiting for password change!)\r'
		
		if fgrep --quiet "$match" "$log"
		then
			pkill -f $PW
			rm $log
	
			greenMessage "Successfully changed your admin password."
			
			if [ -f /lib/systemd/system/sinusbot.service ]; then
				service sinusbot start
				greenMessage "Started your bot with systemd."
			elif [ -f /etc/init.d/sinusbot ]; then
				/etc/init.d/sinusbot start
				greenMessage "Started your bot with initd."
			else
				redMessage "Please start your bot normally"!
				fi
			
			exit
		fi
	done
	
	fi

# Check which OS

if [ "$INSTALL" != "Rem" ]; then

	if [ -f /etc/centos-release ]; then
		greenMessage "Installing redhat-lsb! Please wait."
		yum -y -q install redhat-lsb
		greenMessage "Done"!
	
	fi
	
	if [ -f /etc/debian_version ]; then
		greenMessage "Check if lsb-release and debconf-utils is installed..."
		checkInstall debconf-utils
		checkInstall lsb-release
		greenMessage "Done"!
	
	fi
	
# Functions from lsb_release

    OS=$(lsb_release -i 2> /dev/null | grep 'Distributor' | awk '{print tolower($3)}')
    OSBRANCH=$(lsb_release -c 2> /dev/null | grep 'Codename' | awk '{print $2}')
	
fi

# Go on

	if [ "$INSTALL" != "Rem" ]; then
		if [ -z "$OS" ]; then
			errorExit "Error: Could not detect OS. Currently only Debian, Ubuntu and CentOS are supported. Aborting"! 
			elif [ -z "$OS" ] && ( [ "$(cat /etc/debian_version | awk '{print $1}')" == "7" ] || [ $(cat /etc/debian_version | grep "7.") ] ); then
			errorExit "Debian 7 isn't supported anymore"!
			
			fi 
			
		if [ -z "$OSBRANCH" ] && [ -f /etc/centos-release ]; then
			errorExit "Error: Could not detect branch of OS. Aborting"
			
			fi 
			
		if [ "$MACHINE" == "x86_64" ]; then
			ARCH="amd64"
			else
			errorExit "$MACHINE is not supported"!
			
			fi	
			fi
			
		if [ "$OS" != "ubuntu" ] && [ "$INSTALL" != "Rem" ]; then
			yellowMessage "Which start script should be used? system.d is prefered since Debian 8."
			OPTIONS=("system.d" "init.d")
			select OPTION in "${OPTIONS[@]}"; do
				case "$REPLY" in
					1|2 ) break;;
					*) errorContinue;;
				esac
			done
			
			if [ "$OPTION" == "init.d" ]; then
				OS="ubuntu"

			fi
			fi
	
# Set path or continue with normal
		
		yellowMessage "Automatic usage or own directories?"
		
		OPTIONS=("Automatic" "Own path" "Quit")
		select OPTION in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2 ) break;;
				3 ) errorQuit;;
				*) errorContinue;;
			esac
		done
		
		if [ "$OPTION" == "Automatic" ]; then
			LOCATION=/opt/sinusbot			
			
		elif [ "$OPTION" == "Own path" ]; then
			yellowMessage "Enter location where the bot should be installed/updated/removed. Like /opt/sinusbot. Include the / at first position and none at the end"!
		
			LOCATION=""
				while [[ ! -d $LOCATION ]]; do
					read -p "Location [/opt/sinusbot]: " LOCATION
					if [ "$INSTALL" != "Inst" ] && [ ! -d $LOCATION ]; then
						redMessage "Directory not found, try again"!
						fi
					if [ "$INSTALL" == "Inst" ]; then
					if [ "$LOCATION" == "" ]; then
					LOCATION=/opt/sinusbot
					fi
					makeDir $LOCATION
						fi
				done
			
			greenMessage "Your directory is $LOCATION."
			
			OPTIONS=("Yes" "No, change it" "Quit")
				select OPTION in "${OPTIONS[@]}"; do
					case "$REPLY" in
						1|2 ) break;;
						3 ) errorQuit;;
						*) errorContinue;;
					esac
				done
				
				if [ "$OPTION" == "No, change it" ]; then
					LOCATION=""
					while [[ ! -d $LOCATION ]]; do
						read -p "Location [/opt/sinusbot]: " LOCATION
						if [ "$INSTALL" != "Inst" ] && [ ! -d $LOCATION ]; then
							redMessage "Directory not found, try again"!
							fi
						if [ "$INSTALL" == "Inst" ]; then
						makeDir $LOCATION
							fi
					done
					
					greenMessage "Your directory is $LOCATION."
					
					fi
				
			fi
			
			LOCATIONex=$LOCATION/sinusbot
			
# Check if Sinusbot already installed and if update is possible

	if [ "$INSTALL" == "Inst" ]; then
		if [ -f $LOCATION/sinusbot ]; then
		redMessage "Sinusbot already installed with automatic install option"!
		read -p "Would you like to update the bot instead? [Y / N]: " OPTION
		
			if [ "$OPTION" == "Y" ] || [ "$OPTION" == "y" ] || [ "$OPTION" == "" ]; then
				INSTALL="Updt"
			elif [ "$OPTION" == "N" ] || [ "$OPTION" == "n" ]; then
				errorExit "Installer stops now"!
				
				fi
		else
		greenMessage "Sinusbot isn't installed yet. Installer goes on."

		fi
		
	elif [ "$INSTALL" == "Rem" ] || [ "$INSTALL" == "Updt" ]; then
		if [ ! $LOCATION ]; then
		errorExit "Sinusbot isn't installed"!
		else
		greenMessage "Sinusbot is installed. Installer goes on."

		fi
		fi
	
# Remove Sinusbot

if [ "$INSTALL" == "Rem" ]; then
		
	SINUSBOTUSER=$(ls -ld $LOCATION | awk '{print $3}')
	
	if [ -f /usr/local/bin/youtube-dl ]; then
	redMessage "Remove YoutubeDL?"
	
	OPTIONS=("Yes" "No")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2 ) break;;
            *) errorContinue;;
        esac
    done
	
	if [ "$OPTION" == "Yes" ]; then
	if [ -f /usr/local/bin/youtube-dl ]; then
		rm /usr/local/bin/youtube-dl
		
		fi
		
	if [ -f /etc/cron.d/ytdl ]; then
		rm /etc/cron.d/ytdl
		
		fi
		
	greenMessage "Removed YT-DL successfully"!
	
		fi
	fi
	
	if [ -z $SINUSBOTUSER ]; then
		errorExit "No Sinusbot found. Exiting now."
		fi
	
	redMessage "Sinusbot will now be removed completely from your system"!
	
		greenMessage "Your Sinusbotuser is \"$SINUSBOTUSER\"? After select Yes it could take a while."		
	
	OPTIONS=("Yes" "No")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1 ) break;;
            2 ) errorQuit;;
            *) errorContinue;;
        esac
    done
	
	if [ "$(ps ax | grep sinusbot | grep SCREEN)" ]; then
		ps ax | grep sinusbot | grep SCREEN | awk '{print $1}' | while read PID; do
		kill $PID
		done

		fi
		
	if [ "$(ps ax | grep ts3bot | grep SCREEN)" ]; then
		ps ax | grep ts3bot | grep SCREEN | awk '{print $1}' | while read PID; do
		kill $PID
		done

		fi

	if [ -f /lib/systemd/system/sinusbot.service ] && [ "$OS" != "ubuntu" ]; then
		if [ $(systemctl is-active sinusbot >/dev/null 2>&1 && echo UP || echo DOWN) == "UP" ]; then
			service sinusbot stop 2> /dev/null
			systemctl disable sinusbot 2> /dev/null
			rm /lib/systemd/system/sinusbot.service
		else
			rm /lib/systemd/system/sinusbot.service
		fi
	elif [ -f /etc/init.d/sinusbot ]; then
		if [ "$(/etc/init.d/sinusbot status | awk '{print $NF; exit}')" == "UP" ]; then
			su -c "/etc/init.d/sinusbot stop" $SINUSBOTUSER
			su -c "screen -wipe" $SINUSBOTUSER
			update-rc.d -f sinusbot remove >/dev/null 2>&1
			rm /etc/init.d/sinusbot
		else
			rm /etc/init.d/sinusbot
		fi
		fi
		
	rm /etc/cron.d/sinusbot

	if [ "$LOCATION" ]; then
		rm -R $LOCATION >/dev/null 2>&1
		greenMessage "Files removed successfully"!
		else
		redMessage "Error while removing files."
				
		fi
	
	if [ $SINUSBOTUSER != "root" ]; then
	
	redMessage "Remove user \"$SINUSBOTUSER\"?"
	
	OPTIONS=("Yes" "No")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2 ) break;;
            *) errorContinue;;
        esac
    done
	
	if [ "$OPTION" == "Yes" ]; then
	pkill -9 -u $(id -u $SINUSBOTUSER)
	if [ -f /etc/centos-release ]; then
	userdel -f --remove $SINUSBOTUSER >/dev/null 2>&1
	else
	deluser -f --remove-home $SINUSBOTUSER >/dev/null 2>&1
	fi
	
	if [ "$(id $SINUSBOTUSER 2> /dev/null)" == "" ]; then
		greenMessage "User removed successfully"!
		else
		redMessage "Error while removing user"!
		
		fi
	fi
	fi

			
	greenMessage "Sinusbot removed completely including all directories."
	
exit 0
	
fi
	
# Private usage only!
	
	redMessage "This Sinusbot version is only for private use! Accept?"
	
	OPTIONS=("No" "Yes")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1 ) errorQuit;;
            2 ) break;;
            *) errorContinue;;
        esac
    done
	
# Update packages or not
	
	redMessage 'Update the system packages to the latest version? Recommended, as otherwise dependencies might break! Option "No" = Exit'

    OPTIONS=("Yes" "Try without" "No")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2 ) break;;
            3 ) errorQuit;;
            *) errorContinue;;
        esac
    done
		
	greenMessage "Start installer now"!
	sleep 2
	
	if [ "$OPTION" == "Yes" ]; then
    greenMessage "Updating the system in a few seconds silently (no optical output)"!
	sleep 1
	redMessage "This could take a while. Please wait up to 10 minutes"!
	sleep 3
	
	if [ -f /etc/centos-release ]; then
	yum -y -q update && yum -y -q install curl >/dev/null 2>&1
	else
    apt-get -qq update && apt-get -qq upgrade -y && apt-get -qq install curl -y >/dev/null 2>&1
	fi
	
	elif [ "$OPTION" == "Try without" ]; then
	if [ -f /etc/centos-release ]; then
	yum -y -q install curl >/dev/null 2>&1
	else
	checkInstall curl
	
	fi
	fi	
	fi

# TeamSpeak3-Client latest check || Deactivated till botupdate

#	greenMessage "Searching latest TS3-Client build for hardware type $MACHINE with arch $ARCH."
	
#	for VERSION in ` curl -s http://dl.4players.de/ts/releases/ | grep -Po '(?<=href=")[0-9]+(\.[0-9]+){2,3}(?=/")' | sort -Vr | head -1`; do
#        DOWNLOAD_URL_VERSION="http://dl.4players.de/ts/releases/$VERSION/TeamSpeak3-Client-linux_$ARCH-$VERSION.run"
#        STATUS=`curl -I $DOWNLOAD_URL_VERSION 2>&1 | grep "HTTP/" | awk '{print $2}'`
#        if [ "$STATUS" == "200" ]; then
#            DOWNLOAD_URL=$DOWNLOAD_URL_VERSION
#            break
			
#			fi
#    done
	
#	if [ "$STATUS" == "200" -a "$DOWNLOAD_URL" != "" ]; then
#        greenMessage "Detected latest TS3-Client version as $VERSION with download URL $DOWNLOAD_URL"
#		else
#        errorExit "Could not detect latest TS3-Client version"
		
#		fi

		DOWNLOAD_URL="http://ftp.4players.de/pub/hosted/ts3/releases/3.0.19.4/TeamSpeak3-Client-linux_amd64-3.0.19.4.run"
		VERSION="3.0.19.4"

# Install necessary aptitudes for sinusbot.
	
	magentaMessage "Installing necessary packages! Please wait..."
	
	if [ -f /etc/centos-release ]; then
	yum -y -q install screen x11vnc xvfb libxcursor1 ca-certificates bzip2 psmisc libglib2.0-0 curl less cron-apt ntp ntpdate python >/dev/null 2>&1
	else
	apt-get -qq install screen x11vnc xvfb libxcursor1 ca-certificates bzip2 psmisc libglib2.0-0 curl less cron-apt ntp ntpdate python -y >/dev/null 2>&1
	update-ca-certificates >/dev/null 2>&1
	fi

	
	greenMessage "Packages installed"!

# Create/check user for sinusbot.

	if [ "$INSTALL" == "Updt" ]; then
		SINUSBOTUSER=$(ls -ld $LOCATION | awk '{print $3}')
		
	else 
	
    cyanMessage 'Please enter the name of the sinusbot user. Typically "sinusbot". If it does not exists, the installer will create it.'
	
			SINUSBOTUSER=""
					while [[ ! $SINUSBOTUSER ]]; do
						read -p "Username [sinusbot]: " SINUSBOTUSER
						if [ -z "$SINUSBOTUSER" ]; then
							SINUSBOTUSER=sinusbot
							fi
						if [ -n "$SINUSBOTUSER" ]; then
							greenMessage "Your sinusbot user is: $SINUSBOTUSER"
							fi
					done
		
    if [ "$(id $SINUSBOTUSER 2> /dev/null)" == "" ]; then
            if [ -d /home/$SINUSBOTUSER ]; then
                $GROUPADD $SINUSBOTUSER
                $USERADD -d /home/$SINUSBOTUSER -s /bin/bash -g $SINUSBOTUSER $SINUSBOTUSER
				else
                $GROUPADD $SINUSBOTUSER
                $USERADD -m -b /home -s /bin/bash -g $SINUSBOTUSER $SINUSBOTUSER
				
				fi
		else
        greenMessage "User \"$SINUSBOTUSER\" already exists."
		
		fi
		fi

# Create dirs or remove them.
		
	    ps -u $SINUSBOTUSER | grep ts3client | awk '{print $1}' | while read PID; do
        kill $PID
		done
    if [ -f $LOCATION/ts3client_startscript.run ]; then
        rm -rf $LOCATION/*
		
		fi
	
    makeDir $LOCATION/teamspeak3-client
	
    chmod 750 -R $LOCATION
    chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION
    cd $LOCATION/teamspeak3-client

# Downloading TS3-Client files.

	if [ -f CHANGELOG ] && [ $(cat CHANGELOG | awk '/Client Release/{ print $4; exit }') == $VERSION ]; then
		greenMessage "TS3 already latest version."
	
	else
	
		greenMessage "Downloading TS3 client files."
		su -c "curl -O -s $DOWNLOAD_URL" $SINUSBOTUSER
		fi
	
    if [ ! -f TeamSpeak3-Client-linux_$ARCH-$VERSION.run -a ! -f ts3client_linux_$ARCH ]; then        
		redMessage "Error while downloading TS3-Client with cURL, tying it with wget"
		su -c "wget -q $DOWNLOAD_URL" $SINUSBOTUSER
		
		if [ ! -f TeamSpeak3-Client-linux_$ARCH-$VERSION.run -a ! -f ts3client_linux_$ARCH ]; then		
		errorExit "Download failed! Exiting now"!
		
		fi
  
		fi

# Installing TS3-Client.
	
	if [ -f TeamSpeak3-Client-linux_$ARCH-$VERSION.run ]; then
		greenMessage "Installing the TS3 client."
		redMessage "Read the eula"!
		sleep 1
		yellowMessage 'Do the following: Press "ENTER" then press "q" after that press "y" and accept it with another "ENTER".'
		sleep 2
	
		chmod 777 ./TeamSpeak3-Client-linux_$ARCH-$VERSION.run
	
		su -c "./TeamSpeak3-Client-linux_$ARCH-$VERSION.run" $SINUSBOTUSER
	
		cp -R ./TeamSpeak3-Client-linux_$ARCH/* ./
		sleep 2
		rm ./ts3client_runscript.sh
		rm ./TeamSpeak3-Client-linux_$ARCH-$VERSION.run
		rm -R ./TeamSpeak3-Client-linux_$ARCH
	
		greenMessage "TS3 client install done."
	
		fi

# Downloading latest Sinusbot.

	cd $LOCATION
	
		greenMessage "Downloading latest Sinusbot."
				
		STATUS=$(curl -I https://www.sinusbot.com/dl/sinusbot-beta.tar.bz2 2>&1 | grep "HTTP/" | awk '{print $2}')
        if [ "$STATUS" == "200" ]; then
			su -c "curl -O -s https://www.sinusbot.com/dl/sinusbot-beta.tar.bz2" $SINUSBOTUSER
			
		else
				redMessage "Error while downloading with cURL (Status = $STATUS). Trying it with wget."
				if  [ -f /etc/centos-release ]; then
				yum -y -q install wget
				fi
				checkInstall wget
				su -c "wget -q https://www.sinusbot.com/dl/sinusbot-beta.tar.bz2" $SINUSBOTUSER
				
			fi

	if [ ! -f sinusbot-beta.tar.bz2 -a ! -f sinusbot ]; then
		errorExit "Download failed! Exiting now"!
		
		fi
		
# Installing latest Sinusbot.
		
		greenMessage "Extracting Sinusbot files."
		su -c "tar -xjf sinusbot-beta.tar.bz2" $SINUSBOTUSER
		rm -f sinusbot-beta.tar.bz2
	
		cp $LOCATION/plugin/libsoundbot_plugin.so $LOCATION/teamspeak3-client/plugins/
	
		chmod 755 sinusbot
		
		if [ "$INSTALL" == "Inst" ]; then
		greenMessage "Sinusbot installation done."
		elif [ "$INSTALL" == "Updt" ]; then
		greenMessage "Sinusbot update done."
		fi	
		
		
	if [ $OS != "ubuntu" ]; then
		
		if [ -f /etc/systemd/system/sinusbot.service ]; then
			service sinusbot stop
			systemctl disable sinusbot
			rm /etc/systemd/system/sinusbot.service
			fi
		
		cd /lib/systemd/system/

		
		STATUS=$(curl -I https://raw.githubusercontent.com/Xuxe/Sinusbot-Startscript/master/sinusbot.service 2>&1 | grep "HTTP/" | awk '{print $2}')
        if [ "$STATUS" == "200" ]; then
			curl -O -s https://raw.githubusercontent.com/Xuxe/Sinusbot-Startscript/master/sinusbot.service
			
		else
				redMessage "Error while downloading systemd script with cURL. Trying it with wget."
				if  [ -f /etc/centos-release ]; then
				yum -y -q install wget
				fi
				checkInstall wget
				wget -q https://raw.githubusercontent.com/Xuxe/Sinusbot-Startscript/master/sinusbot.service
				
			fi
		
		if [ ! -f sinusbot.service ]; then
			errorExit "Download failed! Exiting now"!
		
		fi
		
		sed -i 's/User=YOUR_USER/User='$SINUSBOTUSER'/g' /lib/systemd/system/sinusbot.service
		sed -i 's!ExecStart=YOURPATH_TO_THE_BOT_BINARY!ExecStart='$LOCATIONex'!g' /lib/systemd/system/sinusbot.service
		sed -i 's!WorkingDirectory=YOURPATH_TO_THE_BOT_DIRECTORY!WorkingDirectory='$LOCATION'!g' /lib/systemd/system/sinusbot.service
			
		systemctl daemon-reload &> /dev/null
		systemctl enable sinusbot.service &> /dev/null
		
		greenMessage 'Installed systemd file to start the Sinusbot with "service sinusbot {start|stop|status|restart}"'
		
	elif [ $OS == "ubuntu" ]; then
		
		cd /etc/init.d/
		
		STATUS=$(curl -I https://raw.githubusercontent.com/Qhiliqq/Sinusbot-Startscript/master/sinusbot 2>&1 | grep "HTTP/" | awk '{print $2}')
        if [ "$STATUS" == "200" ]; then
			curl -O -s https://raw.githubusercontent.com/Qhiliqq/Sinusbot-Startscript/master/sinusbot
			
		else
				redMessage "Error while downloading init.d script with cURL. Trying it with wget."
				if  [ -f /etc/centos-release ]; then
				yum -y -q install wget
				fi
				checkInstall wget
				wget -q https://raw.githubusercontent.com/Qhiliqq/Sinusbot-Startscript/master/sinusbot
				
			fi
		
		if [ ! -f sinusbot ]; then
			errorExit "Download failed! Exiting now"!
		
		fi
		
		sed -i 's/USER="mybotuser"/USER="'$SINUSBOTUSER'"/g' /etc/init.d/sinusbot
		sed -i 's!DIR_ROOT="/opt/ts3soundboard/"!DIR_ROOT="'$LOCATION'/"!g' /etc/init.d/sinusbot
	
		chmod +x /etc/init.d/sinusbot
		
		if [ -f /etc/centos-release ]; then
			chkconfig sinusbot on >/dev/null 2>&1
			
		else
			update-rc.d sinusbot defaults >/dev/null 2>&1
			
			fi
		
		greenMessage 'Installed init.d file to start the Sinusbot with "/etc/init.d/sinusbot {start|stop|status|restart|console|update|backup}"'
	
	else
		
		errorExit "Error while checking systemd or init.d script. Ask the author for help."
		
		fi
	
		cd $LOCATION

if [ "$INSTALL" == "Inst" ]; then
	
	if [ ! -f $LOCATION/config.ini ]; then
		echo 'ListenPort = 8087 
		ListenHost = "0.0.0.0" 
		TS3Path = "'$LOCATION'/teamspeak3-client/ts3client_linux_amd64"
		YoutubeDLPath = ""'>>$LOCATION/config.ini
		greenMessage "Config.ini created successfully."
		else
		redMessage "Config.ini already exists or creation error"!
		
		fi
	
fi
	
	if [ $(grep -Pq 'sinusbot' /etc/cron.d/sinusbot &>/dev/null) ]; then
		redMessage "Cronjob already set for Sinusbot updater"!
		else
		greenMessage "Installing Cronjob for automatic Sinusbot update..."
		echo "0 0 * * * su $SINUSBOTUSER $LOCATION/sinusbot -update >/dev/null 2>&1">>/etc/cron.d/sinusbot
		greenMessage "Installing Sinusbot update cronjob successful."
		
		fi		

# Installing YT-DL.

	redMessage "Should YT-DL be installed/updated?"
	OPTIONS=("Yes" "No")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2 ) break;;
            *) errorContinue;;
        esac
    done
	
	if [ "$OPTION" == "Yes" ]; then
	greenMessage "Installing YT-Downloader now"!
	
	if [ "$(grep -c 'youtube' /etc/cron.d/ytdl)" -ge 1 ]; then
		redMessage "Cronjob already set for YT-DL updater"!
		elif [ "$(grep -c 'youtube' /etc/cron.d/ytdl)" == 0 ]; then
		greenMessage "Installing Cronjob for automatic YT-DL update..."
		echo "0 0 * * * su $SINUSBOTUSER youtube-dl -U >/dev/null 2>&1">>/etc/cron.d/ytdl
		greenMessage "Installing Cronjob successful."
		else
		redMessage "Error while installing YoutubeDL Cronjob. Skipping."
		
		fi
		
		sed -i 's/YoutubeDLPath = \"\"/YoutubeDLPath = \"\/usr\/local\/bin\/youtube-dl\"/g' $LOCATION/config.ini
		
		if [ -f /usr/local/bin/youtube-dl ]; then
			rm /usr/local/bin/youtube-dl
			
			fi
	
	STATUS=$(curl -I http://yt-dl.org/downloads/latest/youtube-dl 2>&1 | grep "HTTP/" | awk '{print $2}')
        if [ "$STATUS" == "302" ]; then
			curl -L -s http://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
			
		else
				redMessage "Error while downloading youtube-dl with cURL. Trying it with wget."
				if [ -f /etc/centos-release ]; then
				yum -y -q install wget
				fi
				checkInstall wget
				wget -q -O /usr/local/bin/youtube-dl http://yt-dl.org/downloads/latest/youtube-dl
				
			fi
		
		if [ ! -f /usr/local/bin/youtube-dl ]; then
			errorExit "Download failed! Exiting now"!
		
		fi
	
	chmod a+rx /usr/local/bin/youtube-dl
		
	youtube-dl -U
		
	fi
		
# Creating Readme
	
	if [ ! -a "$LOCATION/README_installer.txt" ] && [ $OS != "ubuntu" ] ; then
	echo '##################################################################################
# #
# Usage: service sinusbot {start|stop|status|restart} #
# - start: start the bot #
# - stop: stop the bot #
# - status: display the status of the bot (down or up) #
# - restart: restart the bot #
# #
##################################################################################'>>$LOCATION/README_installer.txt
	elif [ ! -a "$LOCATION/README_installer.txt" ] && [ $OS == "ubuntu" ] ; then
	echo '##################################################################################
# #
# Usage: /etc/init.d/sinusbot {start|stop|status|restart|console|update|backup} #
# - start: start the bot #
# - stop: stop the bot #
# - status: display the status of the bot (down or up) #
# - restart: restart the bot #
# - console: display the bot console #
# - update: runs the bot updater (with start & stop)
# - backup: archives your bot root directory
# To exit the console without stopping the server, press CTRL + A then D. #
# #
##################################################################################'>>$LOCATION/README_installer.txt
	fi

# Setting server time

	service ntp stop >/dev/null 2>&1
	ntpdate -s 0.pool.ntp.org >/dev/null 2>&1
	service ntp start >/dev/null 2>&1
	
# Starting Sinusbot first time!
	
	if [ "$INSTALL" != "Updt" ]; then
	
	greenMessage 'Starting the Sinusbot. For first time.'
	chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION
	cd $LOCATION

# Password variable
	
	export Q=$(su $SINUSBOTUSER -c './sinusbot --initonly')
	password=$(export | awk '/password/{ print $10 }' | tr -d "'")
	if [ -z "$password" ]; then
		errorExit "Failed to read password, try a reinstall again."
	fi

# Starting bot	

	greenMessage "Starting Sinusbot again. Your admin password = '$password'"
	fi
	if [ $OS != "ubuntu" ]; then
	service sinusbot start
	elif [ $OS == "ubuntu" ]; then
	/etc/init.d/sinusbot start
	fi
	yellowMessage "Please wait... This will take some seconds"!
	chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION
	if [ $OS != "ubuntu" ]; then
	sleep 5
	elif [ $OS == "ubuntu" ]; then
	sleep 10
	fi
	
	if [ -f /etc/centos-release ] ; then
		zone=$(firewall-cmd --get-active-zones | awk '{print $1; exit}')
		firewall-cmd --zone=$zone --add-port=8087/tcp --permanent >/dev/null 2>&1
		firewall-cmd --reload >/dev/null 2>&1
		
		fi

# If startup failed, the script will start normal sinusbot without screen for looking about errors. If startup successed => installation done.
	
	if ([ $(systemctl is-active sinusbot >/dev/null 2>&1 && echo UP || echo DOWN) == "UP" ] && [ $OS != "ubuntu" ]) || ([ $(/etc/init.d/sinusbot status | awk '{print $NF; exit}') == "UP" ] && [ $OS == "ubuntu" ]); then

		if [ "$INSTALL" == "Inst" ]; then
		greenMessage "Install done"!
		elif [ "$INSTALL" == "Updt" ]; then
		greenMessage "Update done"!
		
		fi
		
		if [ ! -f "$LOCATION/README_installer.txt" ]; then
		yellowMessage 'Generated a README_installer.txt in '$LOCATION' with all commands for the sinusbot...'
		
		fi
		
		if [ "$INSTALL" == "Updt" ]; then
		if [ -f /lib/systemd/system/sinusbot.service ]; then
			service sinusbot restart
			greenMessage "Restarted your bot with systemd."
			fi
		if [ -f /etc/init.d/sinusbot ]; then
			/etc/init.d/sinusbot restart
			greenMessage "Restarted your bot with initd."
			fi
		greenMessage 'All right. Everything is updated successfully. Sinusbot is UP on "'$ipaddress':8087" :)'
		else
		greenMessage 'All right. Everything is installed successfully. Sinusbot is UP on "'$ipaddress':8087" :) Your login is user = "admin" and password = "'$password'"'
		fi
		if [ $OS != "ubuntu" ]; then
		redMessage 'Stop it with "service sinusbot stop".'
		elif [ $OS == "ubuntu" ]; then
		redMessage 'Stop it with "/etc/init.d/sinusbot stop".'
		fi
		magentaMessage "Don't forget to rate this script on: https://forum.sinusbot.com/resources/sinusbot-installer-script.58/"
		greenMessage "Thank you for using this script! :)"
		
		else
		
		redMessage "Sinusbot could not start! Starting it directly. Look for errors"!
		su -c "$LOCATION/sinusbot" $SINUSBOTUSER
		
		fi
	
exit 0
