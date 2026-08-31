#!/bin/bash
# mlbserver.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"
hostDir="$9"
cdvrStartingChannel="${10}"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"
# one-clickCdvrNumbering <CDVR starting-channel arg; "#" if unset>
one-clickCdvrNumbering "$cdvrStartingChannel"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"TZ=$4"
"DATA_DIRECTORY=$5"
"ACCOUNT_USERNAME=$6"
"ACCOUNT_PASSWORD=$7"
"FAV_TEAMS=$8"
"ZIP_CODE=0"
"HOST_DIR=$9"
)

synologyDirs=(
"$hostDir/mlbserver"
)

# one-clickCreateStack -- no args; uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp

# one-clickRegisterSource <CDVR source slug> <channel JSON>
# one-clickChannelJson name=.. url=.. [type=HLS] [source=URL] [text=..] [limit=..] [xmltv=..] [start=..] [numbering=..] [refresh=24]
one-clickRegisterSource mlbserver \
  "$(one-clickChannelJson name=mlbserver \
     url="http://$extensionURL/channels.m3u?mediaType=Video&resolution=best" \
     xmltv="http://$extensionURL/guide.xml?mediaType=Video&includeTeamsInTitles=channels&offAir=channels")"
