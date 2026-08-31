#!/bin/bash
# prismcast.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$4"
cdvrStartingChannel="$8"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"
# one-clickCdvrNumbering <CDVR starting-channel arg; "#" if unset>
one-clickCdvrNumbering "$cdvrStartingChannel"

envVars=(
"TAG=$2"
"DOMAIN=$3"
"HOST_PORT=$4"
"HOST_VNC_PORT=$5"
"HOST_NOVNC_PORT=$6"
"HOST_HDHR_PORT=$7"
"DISPLAY_NUM=99"
"SCREEN_WIDTH=1920"
"SCREEN_HEIGHT=1080"
"SCREEN_DEPTH=24"
"CDVR_STARTING_CHANNEL=$8"
"TZ=$9"
"DEVICES=${10}"
"LIBVA_DRIVER_NAME=${11}"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp

# one-clickRegisterSource <CDVR source slug> <channel JSON>
# one-clickChannelJson name=.. url=.. [type=HLS] [source=URL] [text=..] [limit=..] [xmltv=..] [start=..]
one-clickRegisterSource prismcast \
  "$(one-clickChannelJson name=PrismCast url="http://$extensionURL/playlist")"
