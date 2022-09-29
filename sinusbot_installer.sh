#!/bin/bash
# SinusBot installer by Philipp Eßwein - DAThosting.eu philipp.esswein@dathosting.eu

# Vars

MACHINE=$(uname -m)
Instversion="1.5"

USE_SYSTEMD=true

# Functions

function greenMessage() {
  echo -e "\\033[32;1m${*}\\033[0m"
}

function magentaMessage() {
  echo -e "\\033[35;1m${*}\\033[0m"
}

function cyanMessage() {
  echo -e "\\033[36;1m${*}\\033[0m"
}

function redMessage() {
  echo -e "\\033[31;1m${*}\\033[0m"
}

function yellowMessage() {
  echo -e "\\033[33;1m${*}\\033[0m"
}

function errorQuit() {
  errorExit 'Exit now!'
}

function errorExit() {
  redMessage "${@}"
  exit 1
}

function errorContinue() {
  redMessage "Invalid option."
  return
}

function makeDir() {
  if [ -n "$1" ] && [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
}

err_report() {
  FAILED_COMMAND=$(wget -q -O - https://raw.githubusercontent.com/Sinusbot/installer-linux/master/sinusbot_installer.sh | sed -e "$1q;d")
  FAILED_COMMAND=${FAILED_COMMAND/ -qq}
  FAILED_COMMAND=${FAILED_COMMAND/ -q}
  FAILED_COMMAND=${FAILED_COMMAND/ -s}
  FAILED_COMMAND=${FAILED_COMMAND/ 2\>\/dev\/null\/}
  FAILED_COMMAND=${FAILED_COMMAND/ 2\>&1}
  FAILED_COMMAND=${FAILED_COMMAND/ \>\/dev\/null}
  if [[ "$FAILED_COMMAND" == "" ]]; then
    redMessage "Failed command: https://github.com/Sinusbot/installer-linux/blob/master/sinusbot_installer.sh#L""$1"
  else
    redMessage "Command which failed was: \"${FAILED_COMMAND}\". Please try to execute it manually and attach the output to the bug report in the forum thread."
    redMessage "If it still doesn't work report this to the author at https://forum.sinusbot.com/threads/sinusbot-installer-script.1200/ only. Not a PN or a bad review, cause this is an error of your system not of the installer script. Line $1."
  fi
  exit 1
}

trap 'err_report $LINENO' ERR

# Check if the script was run as root user. Otherwise exit the script
if [ "$(id -u)" != "0" ]; then
  errorExit "Change to root account required!"
fi

# Update notify

cyanMessage "Checking for the latest installer version"
if [[ -f /etc/centos-release ]]; then
  yum -y -q install wget
else
  apt-get -qq install wget -y
fi

# Detect if systemctl is available then use systemd as start script. Otherwise use init.d
if [[ $(command -v systemctl) == "" ]]; then
  USE_SYSTEMD=false
fi

# If kernel to old, quit
if [ $(uname -r | cut -c1-1) < 3 ]; then
  errorExit "Linux kernel unsupportet. Update kernel before. Or change hardware."
fi

# If the linux distribution is not debian and centos, then exit
if [ ! -f /etc/debian_version ] && [ ! -f /etc/centos-release ]; then
  errorExit "Not supported linux distribution. Only Debian and CentOS are currently supported"!
fi

greenMessage "This is the automatic installer for latest SinusBot. USE AT YOUR OWN RISK"!
sleep 1
cyanMessage "You can choose between installing, upgrading and removing the SinusBot."
sleep 1
redMessage "Installer by Philipp Esswein | DAThosting.eu - Your game-/voiceserver hoster (only german)."
sleep 1
magentaMessage "Please rate this script at: https://forum.sinusbot.com/resources/sinusbot-installer-script.58/"
sleep 1
yellowMessage "You're using installer $Instversion"

# selection menu if the installer should install, update, remove or pw reset the SinusBot
redMessage "What should the installer do?"
OPTIONS=("Install" "Update" "Remove" "PW Reset" "Quit")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1 | 2 | 3 | 4) break ;;
  5) errorQuit ;;
  *) errorContinue ;;
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

if [[ $INSTALL == "Res" ]]; then
  yellowMessage "Automatic usage or own directories?"

  OPTIONS=("Automatic" "Own path" "Quit")
  select OPTION in "${OPTIONS[@]}"; do
    case "$REPLY" in
    1 | 2) break ;;
    3) errorQuit ;;
    *) errorContinue ;;
    esac
  done

  if [ "$OPTION" == "Automatic" ]; then
    LOCATION=/opt/sinusbot
  elif [ "$OPTION" == "Own path" ]; then
    yellowMessage "Enter location where the bot should be installed/updated/removed. Like /opt/sinusbot. Include the / at first position and none at the end"!

    LOCATION=""
    while [[ ! -d $LOCATION ]]; do
      read -rp "Location [/opt/sinusbot]: " LOCATION
      if [[ $INSTALL != "Inst" && ! -d $LOCATION ]]; then
        redMessage "Directory not found, try again"!
      fi
    done

    greenMessage "Your directory is $LOCATION."

    OPTIONS=("Yes" "No, change it" "Quit")
    select OPTION in "${OPTIONS[@]}"; do
      case "$REPLY" in
      1 | 2) break ;;
      3) errorQuit ;;
      *) errorContinue ;;
      esac
    done

    if [ "$OPTION" == "No, change it" ]; then
      LOCATION=""
      while [[ ! -d $LOCATION ]]; do
        read -rp "Location [/opt/sinusbot]: " LOCATION
        if [[ $INSTALL != "Inst" && ! -d $LOCATION ]]; then
          redMessage "Directory not found, try again"!
        fi
      done

      greenMessage "Your directory is $LOCATION."
    fi
  fi

  LOCATIONex=$LOCATION/sinusbot

  if [[ ! -f $LOCATION/sinusbot ]]; then
    errorExit "SinusBot wasn't found at $LOCATION. Exiting script."
  fi

  PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
  SINUSBOTUSER=$(ls -ld $LOCATION | awk '{print $3}')

  greenMessage "Please login to your SinusBot webinterface as admin and '$PW'"
  yellowMessage "After that change your password under Settings->User Accounts->admin->Edit. The script restart the bot with init.d or systemd."

  if [[ -f /lib/systemd/system/sinusbot.service ]]; then
    if [[ $(systemctl is-active sinusbot >/dev/null && echo UP || echo DOWN) == "UP" ]]; then
      service sinusbot stop
    fi
  elif [[ -f /etc/init.d/sinusbot ]]; then
    if [ "$(/etc/init.d/sinusbot status | awk '{print $NF; exit}')" == "UP" ]; then
      /etc/init.d/sinusbot stop
    fi
  fi

  log="/tmp/sinusbot.log"
  match="USER-PATCH [admin] (admin) OK"

  su -c "$LOCATIONex --override-password $PW" $SINUSBOTUSER >"$log" 2>&1 &
  sleep 3

  while true; do
    echo -ne '(Waiting for password change!)\r'

    if grep -Fq "$match" "$log"; then
      pkill -INT -f $PW
      rm $log

      greenMessage "Successfully changed your admin password."

      if [[ -f /lib/systemd/system/sinusbot.service ]]; then
        service sinusbot start
        greenMessage "Started your bot with systemd."
      elif [[ -f /etc/init.d/sinusbot ]]; then
        /etc/init.d/sinusbot start
        greenMessage "Started your bot with initd."
      else
        redMessage "Please start your bot normally"!
      fi
      exit 0
    fi
  done

fi

# Check which OS

if [ "$INSTALL" != "Rem" ]; then

  if [[ -f /etc/centos-release ]]; then
    greenMessage "Installing redhat-lsb! Please wait."
    yum -y -q install redhat-lsb
    greenMessage "Done"!

    yellowMessage "You're running CentOS. Which firewallsystem are you using?"

    OPTIONS=("IPtables" "Firewalld")
    select OPTION in "${OPTIONS[@]}"; do
      case "$REPLY" in
      1 | 2) break ;;
      *) errorContinue ;;
      esac
    done

    if [ "$OPTION" == "IPtables" ]; then
      FIREWALL="ip"
    elif [ "$OPTION" == "Firewalld" ]; then
      FIREWALL="fd"
    fi
  fi

  if [[ -f /etc/debian_version ]]; then
    greenMessage "Check if lsb-release and debconf-utils is installed..."
    apt-get -qq update
    apt-get -qq install debconf-utils -y
    apt-get -qq install lsb-release -y
    greenMessage "Done"!
  fi

  # Functions from lsb_release

  OS=$(lsb_release -i 2>/dev/null | grep 'Distributor' | awk '{print tolower($3)}')
  OSBRANCH=$(lsb_release -c 2>/dev/null | grep 'Codename' | awk '{print $2}')
  OSRELEASE=$(lsb_release -r 2>/dev/null | grep 'Release' | awk '{print $2}')
  VIRTUALIZATION_TYPE=""

  # Extracted from the virt-what sourcecode: http://git.annexia.org/?p=virt-what.git;a=blob_plain;f=virt-what.in;hb=HEAD
  if [[ -f "/.dockerinit" ]]; then
    VIRTUALIZATION_TYPE="docker"
  fi
  if [ -d "/proc/vz" -a ! -d "/proc/bc" ]; then
    VIRTUALIZATION_TYPE="openvz"
  fi

  if [[ $VIRTUALIZATION_TYPE == "openvz" ]]; then
    redMessage "Warning, your server is running OpenVZ! This very old container system isn't well supported by newer packages."
  elif [[ $VIRTUALIZATION_TYPE == "docker" ]]; then
    redMessage "Warning, your server is running Docker! Maybe there are failures while installing."
  fi

fi

# Go on

if [ "$INSTALL" != "Rem" ]; then
  if [ -z "$OS" ]; then
    errorExit "Error: Could not detect OS. Currently only Debian, Ubuntu and CentOS are supported. Aborting"!
  elif [ -z "$OS" ] && ([ "$(cat /etc/debian_version | awk '{print $1}')" == "7" ] || [ $(cat /etc/debian_version | grep "7.") ]); then
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

if [[ "$INSTALL" != "Rem" ]]; then
  if [[ "$USE_SYSTEMD" == true ]]; then
    yellowMessage "Automatically chosen system.d for your startscript"!
  else
    yellowMessage "Automatically chosen init.d for your startscript"!
  fi
fi

# Set path or continue with normal

yellowMessage "Automatic usage or own directories?"

OPTIONS=("Automatic" "Own path" "Quit")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1 | 2) break ;;
  3) errorQuit ;;
  *) errorContinue ;;
  esac
done

if [ "$OPTION" == "Automatic" ]; then
  LOCATION=/opt/sinusbot
elif [ "$OPTION" == "Own path" ]; then
  yellowMessage "Enter location where the bot should be installed/updated/removed, e.g. /opt/sinusbot. Include the / at first position and none at the end"!
  LOCATION=""
  while [[ ! -d $LOCATION ]]; do
    read -rp "Location [/opt/sinusbot]: " LOCATION
    if [[ $INSTALL != "Inst" && ! -d $LOCATION ]]; then
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
    1 | 2) break ;;
    3) errorQuit ;;
    *) errorContinue ;;
    esac
  done

  if [ "$OPTION" == "No, change it" ]; then
    LOCATION=""
    while [[ ! -d $LOCATION ]]; do
      read -rp "Location [/opt/sinusbot]: " LOCATION
      if [[ $INSTALL != "Inst" && ! -d $LOCATION ]]; then
        redMessage "Directory not found, try again"!
      fi
      if [ "$INSTALL" == "Inst" ]; then
        makeDir $LOCATION
      fi
    done

    greenMessage "Your directory is $LOCATION."
  fi
fi

makeDir $LOCATION

LOCATIONex=$LOCATION/sinusbot

# Check if SinusBot already installed and if update is possible

if [[ $INSTALL == "Inst" ]] || [[ $INSTALL == "Updt" ]]; then

yellowMessage "Should I install TeamSpeak or only Discord Mode?"

OPTIONS=("Both" "Only Discord" "Quit")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1 | 2) break ;;
  3) errorQuit ;;
  *) errorContinue ;;
  esac
done

if [ "$OPTION" == "Both" ]; then
  DISCORD="false"
else
  DISCORD="true"
fi
fi

if [[ $INSTALL == "Inst" ]]; then

  if [[ -f $LOCATION/sinusbot ]]; then
    redMessage "SinusBot already installed with automatic install option"!
    read -rp "Would you like to update the bot instead? [Y / N]: " OPTION

    if [ "$OPTION" == "Y" ] || [ "$OPTION" == "y" ] || [ "$OPTION" == "" ]; then
      INSTALL="Updt"
    elif [ "$OPTION" == "N" ] || [ "$OPTION" == "n" ]; then
      errorExit "Installer stops now"!
    fi
  else
    greenMessage "SinusBot isn't installed yet. Installer goes on."
  fi

elif [ "$INSTALL" == "Rem" ] || [ "$INSTALL" == "Updt" ]; then
  if [ ! -d $LOCATION ]; then
    errorExit "SinusBot isn't installed"!
  else
    greenMessage "SinusBot is installed. Installer goes on."
  fi
fi

# Remove SinusBot

if [ "$INSTALL" == "Rem" ]; then

  SINUSBOTUSER=$(ls -ld $LOCATION | awk '{print $3}')

  if [[ -f /usr/local/bin/youtube-dl ]]; then
    redMessage "Remove YoutubeDL?"

    OPTIONS=("Yes" "No")
    select OPTION in "${OPTIONS[@]}"; do
      case "$REPLY" in
      1 | 2) break ;;
      *) errorContinue ;;
      esac
    done

    if [ "$OPTION" == "Yes" ]; then
      if [[ -f /usr/local/bin/youtube-dl ]]; then
        rm /usr/local/bin/youtube-dl
      fi

      if [[ -f /etc/cron.d/ytdl ]]; then
        rm /etc/cron.d/ytdl
      fi

      greenMessage "Removed YT-DL successfully"!
    fi
  fi

  if [[ -z $SINUSBOTUSER ]]; then
    errorExit "No SinusBot found. Exiting now."
  fi

  redMessage "SinusBot will now be removed completely from your system"!

  greenMessage "Your SinusBot user is \"$SINUSBOTUSER\"? The directory which will be removed is \"$LOCATION\". After select Yes it could take a while."

  OPTIONS=("Yes" "No")
  select OPTION in "${OPTIONS[@]}"; do
    case "$REPLY" in
    1) break ;;
    2) errorQuit ;;
    *) errorContinue ;;
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

  if [[ -f /lib/systemd/system/sinusbot.service ]]; then
    if [[ $(systemctl is-active sinusbot >/dev/null && echo UP || echo DOWN) == "UP" ]]; then
      service sinusbot stop
      systemctl disable sinusbot
    fi
    rm /lib/systemd/system/sinusbot.service
  elif [[ -f /etc/init.d/sinusbot ]]; then
    if [ "$(/etc/init.d/sinusbot status | awk '{print $NF; exit}')" == "UP" ]; then
      su -c "/etc/init.d/sinusbot stop" $SINUSBOTUSER
      su -c "screen -wipe" $SINUSBOTUSER
      update-rc.d -f sinusbot remove >/dev/null
    fi
    rm /etc/init.d/sinusbot
  fi

  if [[ -f /etc/cron.d/sinusbot ]]; then
    rm /etc/cron.d/sinusbot
  fi

  if [ "$LOCATION" ]; then
    rm -R $LOCATION >/dev/null
    greenMessage "Files removed successfully"!
  else
    redMessage "Error while removing files."
  fi

  if [[ $SINUSBOTUSER != "root" ]]; then
    redMessage "Remove user \"$SINUSBOTUSER\"? (User will be removed from your system)"

    OPTIONS=("Yes" "No")
    select OPTION in "${OPTIONS[@]}"; do
      case "$REPLY" in
      1 | 2) break ;;
      *) errorContinue ;;
      esac
    done

    if [ "$OPTION" == "Yes" ]; then
      userdel -r -f $SINUSBOTUSER >/dev/null

      if [ "$(id $SINUSBOTUSER 2>/dev/null)" == "" ]; then
        greenMessage "User removed successfully"!
      else
        redMessage "Error while removing user"!
      fi
    fi
  fi

  greenMessage "SinusBot removed completely including all directories."

  exit 0
fi

# Private usage only!

redMessage "This SinusBot version is only for private use! Accept?"

OPTIONS=("No" "Yes")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1) errorQuit ;;
  2) break ;;
  *) errorContinue ;;
  esac
done

# Ask for YT-DL

redMessage "Should YT-DL be installed/updated?"
OPTIONS=("Yes" "No")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1 | 2) break ;;
  *) errorContinue ;;
  esac
done

if [ "$OPTION" == "Yes" ]; then
  YT="Yes"
fi

# Update packages or not

redMessage 'Update the system packages to the latest version? (Recommended)'

OPTIONS=("Yes" "No")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1 | 2) break ;;
  *) errorContinue ;;
  esac
done

greenMessage "Starting the installer now"!
sleep 2

if [ "$OPTION" == "Yes" ]; then
  greenMessage "Updating the system in a few seconds"!
  sleep 1
  redMessage "This could take a while. Please wait up to 10 minutes"!
  sleep 3

  if [[ -f /etc/centos-release ]]; then
    yum -y -q update
    yum -y -q upgrade
  else
    apt-get -qq update
    apt-get -qq upgrade
  fi
fi

# TeamSpeak3-Client latest check

if [ "$DISCORD" == "false" ]; then

greenMessage "Searching latest TS3-Client build for hardware type $MACHINE with arch $ARCH."

VERSION="3.5.6"

DOWNLOAD_URL_VERSION="https://files.teamspeak-services.com/releases/client/$VERSION/TeamSpeak3-Client-linux_$ARCH-$VERSION.run"
 STATUS=$(wget --server-response -L $DOWNLOAD_URL_VERSION 2>&1 | awk '/^  HTTP/{print $2}')
  if [ "$STATUS" == "200" ]; then
    DOWNLOAD_URL=$DOWNLOAD_URL_VERSION
  fi

if [ "$STATUS" == "200" -a "$DOWNLOAD_URL" != "" ]; then
  greenMessage "Detected latest TS3-Client version as $VERSION"
else
  errorExit "Could not detect latest TS3-Client version"
fi

# Install necessary aptitudes for sinusbot.

magentaMessage "Installing necessary packages. Please wait..."

if [[ -f /etc/centos-release ]]; then
  yum -y -q install screen xvfb libxcursor1 ca-certificates bzip2 psmisc libglib2.0-0 less cron-apt ntp python iproute which dbus libnss3 libegl1-mesa x11-xkb-utils libasound2 libxcomposite-dev libxi6 libpci3 libxslt1.1 libxkbcommon0 libxss1 >/dev/null
  update-ca-trust extract >/dev/null
else
  # Detect if systemctl is available then use systemd as start script. Otherwise use init.d
  if [ "$OSRELEASE" == "18.04" ] && [ "$OS" == "ubuntu" ]; then
    apt-get -y install chrony
  else
    apt-get -y install ntp
  fi
  apt-get -y -qq install libfontconfig libxtst6 screen xvfb libxcursor1 ca-certificates bzip2 psmisc libglib2.0-0 less cron-apt python iproute2 dbus libnss3 libegl1-mesa x11-xkb-utils libasound2 libxcomposite-dev libxi6 libpci3 libxslt1.1 libxkbcommon0 libxss1
  update-ca-certificates >/dev/null
fi

else

magentaMessage "Installing necessary packages. Please wait..."

if [[ -f /etc/centos-release ]]; then
  yum -y -q install ca-certificates bzip2 python wget >/dev/null
  update-ca-trust extract >/dev/null
else
  apt-get -qq install ca-certificates bzip2 python wget -y >/dev/null
  update-ca-certificates >/dev/null
fi

fi

greenMessage "Packages installed"!

# Setting server time

if [[ $VIRTUALIZATION_TYPE == "openvz" ]]; then
  redMessage "You're using OpenVZ virtualization. You can't set your time, maybe it works but there is no guarantee. Skipping this part..."
else
  if [[ -f /etc/centos-release ]] || [ $(cat /etc/*release | grep "DISTRIB_ID=" | sed 's/DISTRIB_ID=//g') ]; then
    if [ "$OSRELEASE" == "18.04" ] && [ "$OS" == "ubuntu" ]; then
      systemctl start chronyd
      if [[ $(chronyc -a 'burst 4/4') == "200 OK" ]]; then
        TIME=$(date)
      else
        errorExit "Error while setting time via chrony"!
      fi
    else
      if [[ -f /etc/centos-release ]]; then
       service ntpd stop
      else
       service ntp stop
      fi
      ntpd -s 0.pool.ntp.org
      if [[ -f /etc/centos-release ]]; then
       service ntpd start
      else
       service ntp start
      fi
      TIME=$(date)
    fi
    greenMessage "Automatically set time to" $TIME!
  else
    if [[ $(command -v timedatectl) != "" ]]; then
      service ntp restart
      timedatectl set-ntp yes
      timedatectl
      TIME=$(date)
      greenMessage "Automatically set time to" $TIME!
    else
      redMessage "Unable to configure your date automatically, the installation will still be attempted."
    fi
  fi
fi

USERADD=$(which useradd)
GROUPADD=$(which groupadd)
ipaddress=$(ip route get 8.8.8.8 | awk {'print $7'} | tr -d '\n')

# Create/check user for sinusbot.

if [ "$INSTALL" == "Updt" ]; then
  SINUSBOTUSER=$(ls -ld $LOCATION | awk '{print $3}')
  if [ "$DISCORD" == "false" ]; then
    sed -i "s|TS3Path = \"\"|TS3Path = \"$LOCATION/teamspeak3-client/ts3client_linux_amd64\"|g" $LOCATION/config.ini && greenMessage "Added TS3 Path to config." || redMessage "Error while updating config"
  fi
else

  cyanMessage 'Please enter the name of the sinusbot user. Typically "sinusbot". If it does not exists, the installer will create it.'

  SINUSBOTUSER=""
  while [[ ! $SINUSBOTUSER ]]; do
    read -rp "Username [sinusbot]: " SINUSBOTUSER
    if [ -z "$SINUSBOTUSER" ]; then
      SINUSBOTUSER=sinusbot
    fi
    if [ $SINUSBOTUSER == "root" ]; then
      redMessage "Error. Your username is invalid. Don't use root"!
      SINUSBOTUSER=""
    fi
    if [ -n "$SINUSBOTUSER" ]; then
      greenMessage "Your sinusbot user is: $SINUSBOTUSER"
    fi
  done

  if [ "$(id $SINUSBOTUSER 2>/dev/null)" == "" ]; then
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

chmod 750 -R $LOCATION
chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION

fi

# Create dirs or remove them.

ps -u $SINUSBOTUSER | grep ts3client | awk '{print $1}' | while read PID; do
  kill $PID
done
if [[ -f $LOCATION/ts3client_startscript.run ]]; then
  rm -rf $LOCATION/*
fi

if [ "$DISCORD" == "false" ]; then

makeDir $LOCATION/teamspeak3-client

chmod 750 -R $LOCATION
chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION
cd $LOCATION/teamspeak3-client

# Downloading TS3-Client files.

if [[ -f CHANGELOG ]] && [ $(cat CHANGELOG | awk '/Client Release/{ print $4; exit }') == $VERSION ]; then
  greenMessage "TS3 already latest version."
else

  greenMessage "Downloading TS3 client files."
  su -c "wget -q $DOWNLOAD_URL" $SINUSBOTUSER

  if [[ ! -f TeamSpeak3-Client-linux_$ARCH-$VERSION.run && ! -f ts3client_linux_$ARCH ]]; then
    errorExit "Download failed! Exiting now"!
  fi
fi

# Installing TS3-Client.

if [[ -f TeamSpeak3-Client-linux_$ARCH-$VERSION.run ]]; then
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
fi

# Downloading latest SinusBot.

cd $LOCATION

greenMessage "Downloading latest SinusBot."

su -c "wget -q https://www.sinusbot.com/dl/sinusbot.current.tar.bz2" $SINUSBOTUSER
if [[ ! -f sinusbot.current.tar.bz2 && ! -f sinusbot ]]; then
  errorExit "Download failed! Exiting now"!
fi

# Installing latest SinusBot.

greenMessage "Extracting SinusBot files."
su -c "tar -xjf sinusbot.current.tar.bz2" $SINUSBOTUSER
rm -f sinusbot.current.tar.bz2

if [ "$DISCORD" == "false" ]; then

if [ ! -d teamspeak3-client/plugins/ ]; then
  mkdir teamspeak3-client/plugins/
fi

# Copy the SinusBot plugin into the teamspeak clients plugin directory
cp $LOCATION/plugin/libsoundbot_plugin.so $LOCATION/teamspeak3-client/plugins/

if [[ -f teamspeak3-client/xcbglintegrations/libqxcb-glx-integration.so ]]; then
  rm teamspeak3-client/xcbglintegrations/libqxcb-glx-integration.so
fi
fi

chmod 755 sinusbot

if [ "$INSTALL" == "Inst" ]; then
  greenMessage "SinusBot installation done."
elif [ "$INSTALL" == "Updt" ]; then
  greenMessage "SinusBot update done."
fi

if [[ "$USE_SYSTEMD" == true ]]; then

  greenMessage "Starting systemd installation"

  if [[ -f /etc/systemd/system/sinusbot.service ]]; then
    service sinusbot stop
    systemctl disable sinusbot
    rm /etc/systemd/system/sinusbot.service
  fi

  cd /lib/systemd/system/

  wget -q https://raw.githubusercontent.com/Sinusbot/linux-startscript/master/sinusbot.service

  if [ ! -f sinusbot.service ]; then
    errorExit "Download failed! Exiting now"!
  fi

  sed -i 's/User=YOUR_USER/User='$SINUSBOTUSER'/g' /lib/systemd/system/sinusbot.service
  sed -i 's!ExecStart=YOURPATH_TO_THE_BOT_BINARY!ExecStart='$LOCATIONex'!g' /lib/systemd/system/sinusbot.service
  sed -i 's!WorkingDirectory=YOURPATH_TO_THE_BOT_DIRECTORY!WorkingDirectory='$LOCATION'!g' /lib/systemd/system/sinusbot.service

  systemctl daemon-reload
  systemctl enable sinusbot.service

  greenMessage 'Installed systemd file to start the SinusBot with "service sinusbot {start|stop|status|restart}"'

elif [[ "$USE_SYSTEMD" == false ]]; then

  greenMessage "Starting init.d installation"

  cd /etc/init.d/

  wget -q https://raw.githubusercontent.com/Sinusbot/linux-startscript/obsolete-init.d/sinusbot

  if [ ! -f sinusbot ]; then
    errorExit "Download failed! Exiting now"!
  fi

  sed -i 's/USER="mybotuser"/USER="'$SINUSBOTUSER'"/g' /etc/init.d/sinusbot
  sed -i 's!DIR_ROOT="/opt/ts3soundboard/"!DIR_ROOT="'$LOCATION'/"!g' /etc/init.d/sinusbot

  chmod +x /etc/init.d/sinusbot

  if [[ -f /etc/centos-release ]]; then
    chkconfig sinusbot on >/dev/null
  else
    update-rc.d sinusbot defaults >/dev/null
  fi

  greenMessage 'Installed init.d file to start the SinusBot with "/etc/init.d/sinusbot {start|stop|status|restart|console|update|backup}"'
fi

cd $LOCATION

if [ "$INSTALL" == "Inst" ]; then
  if [ "$DISCORD" == "false" ]; then
    if [[ ! -f $LOCATION/config.ini ]]; then
      echo 'ListenPort = 8087
      ListenHost = "0.0.0.0"
      TS3Path = "'$LOCATION'/teamspeak3-client/ts3client_linux_amd64"
      YoutubeDLPath = ""' >>$LOCATION/config.ini
      greenMessage "config.ini created successfully."
    else
      redMessage "config.ini already exists or creation error"!
    fi
  else
    if [[ ! -f $LOCATION/config.ini ]]; then
      echo 'ListenPort = 8087
      ListenHost = "0.0.0.0"
      TS3Path = ""
      YoutubeDLPath = ""' >>$LOCATION/config.ini
      greenMessage "config.ini created successfully."
    else
      redMessage "config.ini already exists or creation error"!
    fi
  fi
fi

#if [[ -f /etc/cron.d/sinusbot ]]; then
#  redMessage "Cronjob already set for SinusBot updater"!
#else
#  greenMessage "Installing Cronjob for automatic SinusBot update..."
#  echo "0 0 * * * $SINUSBOTUSER $LOCATION/sinusbot -update >/dev/null" >>/etc/cron.d/sinusbot
#  greenMessage "Installing SinusBot update cronjob successful."
#fi

# Installing YT-DL.

if [ "$YT" == "Yes" ]; then
  greenMessage "Installing YT-Downloader now"!
  if [ "$(cat /etc/cron.d/ytdl)" == "0 0 * * * $SINUSBOTUSER youtube-dl -U --restrict-filename >/dev/null" ]; then
        rm /etc/cron.d/ytdl
        yellowMessage "Deleted old YT-DL cronjob. Generating new one in a second."
  fi
  if [[ -f /etc/cron.d/ytdl ]] && [ "$(grep -c 'youtube' /etc/cron.d/ytdl)" -ge 1 ]; then
    redMessage "Cronjob already set for YT-DL updater"!
  else
    greenMessage "Installing Cronjob for automatic YT-DL update..."
    echo "0 0 * * * $SINUSBOTUSER PATH=$PATH:/usr/local/bin; youtube-dl -U --restrict-filename >/dev/null" >>/etc/cron.d/ytdl
    greenMessage "Installing Cronjob successful."
  fi

  sed -i 's/YoutubeDLPath = \"\"/YoutubeDLPath = \"\/usr\/local\/bin\/youtube-dl\"/g' $LOCATION/config.ini

  if [[ -f /usr/local/bin/youtube-dl ]]; then
    rm /usr/local/bin/youtube-dl
  fi

  greenMessage "Downloading YT-DL now..."
  wget -q -O /usr/local/bin/youtube-dl http://yt-dl.org/downloads/latest/youtube-dl

  if [ ! -f /usr/local/bin/youtube-dl ]; then
    errorExit "Download failed! Exiting now"!
  else
    greenMessage "Download successful"!
  fi

  chmod a+rx /usr/local/bin/youtube-dl

  youtube-dl -U --restrict-filename

fi

# Creating Readme

if [ ! -a "$LOCATION/README_installer.txt" ] && [ "$USE_SYSTEMD" == true ]; then
  echo '##################################################################################
# #
# Usage: service sinusbot {start|stop|status|restart} #
# - start: start the bot #
# - stop: stop the bot #
# - status: display the status of the bot (down or up) #
# - restart: restart the bot #
# #
##################################################################################' >>$LOCATION/README_installer.txt
elif [ ! -a "$LOCATION/README_installer.txt" ] && [ "$USE_SYSTEMD" == false ]; then
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
  ##################################################################################' >>$LOCATION/README_installer.txt
fi

greenMessage "Generated README_installer.txt"!

# Delete files if exists

if [[ -f /tmp/.sinusbot.lock ]]; then
  rm /tmp/.sinusbot.lock
  greenMessage "Deleted /tmp/.sinusbot.lock"
fi

if [ -e /tmp/.X11-unix/X40 ]; then
  rm /tmp/.X11-unix/X40
  greenMessage "Deleted /tmp/.X11-unix/X40"
fi

# Starting SinusBot first time!

if [ "$INSTALL" != "Updt" ]; then
  greenMessage 'Starting the SinusBot. For first time.'
  chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION
  cd $LOCATION

  # Password variable

  export Q=$(su $SINUSBOTUSER -c './sinusbot --initonly')
  password=$(export | awk '/password/{ print $10 }' | tr -d "'")
  if [ -z "$password" ]; then
    errorExit "Failed to read password, try a reinstall again."
  fi

  chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION

  # Starting bot
  greenMessage "Starting SinusBot again."
fi

if [[ "$USE_SYSTEMD" == true ]]; then
  service sinusbot start
elif [[ "$USE_SYSTEMD" == false ]]; then
  /etc/init.d/sinusbot start
fi
yellowMessage "Please wait... This will take some seconds"!
chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION

if [[ "$USE_SYSTEMD" == true ]]; then
  sleep 5
elif [[ "$USE_SYSTEMD" == false ]]; then
  sleep 10
fi

if [[ -f /etc/centos-release ]]; then
  if [ "$FIREWALL" == "ip" ]; then
    iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 8087 -j ACCEPT
  elif [ "$FIREWALL" == "fs" ]; then
    if rpm -q --quiet firewalld; then
      zone=$(firewall-cmd --get-active-zones | awk '{print $1; exit}')
      firewall-cmd --zone=$zone --add-port=8087/tcp --permanent >/dev/null
      firewall-cmd --reload >/dev/null
    fi
  fi
fi

# If startup failed, the script will start normal sinusbot without screen for looking about errors. If startup successed => installation done.
IS_RUNNING=false
if [[ "$USE_SYSTEMD" == true ]]; then
  if [[ $(systemctl is-active sinusbot >/dev/null && echo UP || echo DOWN) == "UP" ]]; then
    IS_RUNNING=true
  fi
elif [[ "$USE_SYSTEMD" == false ]]; then
  if [[ $(/etc/init.d/sinusbot status | awk '{print $NF; exit}') == "UP" ]]; then
     IS_RUNNING=true
  fi
fi

if [[ "$IS_RUNNING" == true ]]; then
  if [[ $INSTALL == "Inst" ]]; then
    greenMessage "Install done"!
  elif [[ $INSTALL == "Updt" ]]; then
    greenMessage "Update done"!
  fi

  if [[ ! -f $LOCATION/README_installer.txt ]]; then
    yellowMessage "Generated a README_installer.txt in $LOCATION with all commands for the sinusbot..."
  fi

  if [[ $INSTALL == "Updt" ]]; then
    if [[ -f /lib/systemd/system/sinusbot.service ]]; then
      service sinusbot restart
      greenMessage "Restarted your bot with systemd."
    fi
    if [[ -f /etc/init.d/sinusbot ]]; then
      /etc/init.d/sinusbot restart
      greenMessage "Restarted your bot with initd."
    fi
    greenMessage "All right. Everything is updated successfully. SinusBot is UP on '$ipaddress:8087' :)"
  else
    greenMessage "All right. Everything is installed successfully. SinusBot is UP on '$ipaddress:8087' :) Your user = 'admin' and password = '$password'"
  fi
  if [[ "$USE_SYSTEMD" == true ]]; then
    redMessage 'Stop it with "service sinusbot stop".'
  elif [[ "$USE_SYSTEMD" == false ]]; then
    redMessage 'Stop it with "/etc/init.d/sinusbot stop".'
  fi
  magentaMessage "Don't forget to rate this script on: https://forum.sinusbot.com/resources/sinusbot-installer-script.58/"
  greenMessage "Thank you for using this script! :)"

else
  redMessage "SinusBot could not start! Starting it directly. Look for errors"!
  su -c "$LOCATION/sinusbot" $SINUSBOTUSER
fi

exit 0
