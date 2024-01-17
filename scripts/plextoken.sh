#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_plextoken_latest.log
plexUserID="$2"
plexPasswd="$3"

finish() {
  cat $logFile
}

trap finish EXIT

urlencode() {
    local unencodedPasswd="${1}"
    local urlencodedPasswd=""
    local passwdLength=${#unencodedPasswd}

    for ((characterPosition = 0; characterPosition < $passwdLength; characterPosition++)); do
        local passwdCharacter="${unencodedPasswd:characterPosition:1}"
        case "${passwdCharacter}" in
            [a-zA-Z0-9.~_-])
                encodedPasswd+="${passwdCharacter}"
                ;;
            *)
                printf -v hex '%02x' "'${passwdCharacter}"
                encodedPasswd+="%${hex^^}"
                ;;
        esac
    done

    echo "${encodedPasswd}"
}

generateToken() {
  if [ -f /config/"$channelsHost"-"$channelsPort"_data/plextoken.txt ]; then
    echo "A Plex token data file has already been generated." > $logFile
    echo "Please delete 'plextoken.txt' if you wish to generate a new token." >> $logFile
    exit 1
  fi

  # User specific vars
  clientID="`echo $RANDOM | md5sum | head -c 23`"
  sessionID="`uuidgen`"

  mkdir -p /config/"$channelsHost"-"$channelsPort"_data
  cd /config/"$channelsHost"-"$channelsPort"_data

  # Get token
  curl "https://plex.tv/api/v2/users/signin?X-Plex-Product=Channels%20DVR&X-Plex-Client-Identifier=${clientID}" -H "Accept: application/json" --data-raw "login=${plexUserID}&password=${plexPasswd}&rememberMe=true" -o "plextoken.txt"
  plexToken="$(grep -Po 'authToken\":\K[^,]+' plextoken.txt | tr -d '"')"
  if [ -z "$plexToken" ]; then
    echo "An error occurred during TOKEN generation" > $logFile
    echo "Please check that valid Plex login credentials and command syntax are used" >> $logFile
    exit 2
  fi

  echo "USERID=${plexUserID}" | tee plexdata.txt > $logFile
  echo "SESSIONID=${sessionID}" | tee -a plexdata.txt >> $logFile
  echo "CLIENTID=${clientID}" | tee -a plexdata.txt >> $logFile
  echo "TOKEN=${plexToken}" | tee -a plexdata.txt >> $logFile

  echo "You should receive a new logon email from Plex for Channels DVR" >> $logFile
}

main() {
  plexPasswd=$(urlencode "$plexPasswd")
  generateToken
}

main
