#!/bin/bash
# mlb.tv-for-channels.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"APP_URL=$4"
"LOG_LEVEL=$5"
"MLB_USERNAME=$6"
"MLB_PASSWORD=$7"
"MLB_BITRATE=$8"
"MLB_PLAYLIST_FIRST_CHANNEL=$9"
"MLB_TEAM_ORDER=${10}"
"MLB_TIMEZONE=${11}"
"MLB_SHOW_TV_FEEDS=${12}"
"MLB_SHOW_RADIO_FEEDS=${13}"
"HOST_VOLUME_APP=${14}"
"HOST_VOLUME_LOGS=${15}"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp

# one-clickRegisterSource <CDVR source slug> <channel JSON>
# one-clickChannelJson name=.. url=.. [type=HLS] [source=URL] [text=..] [limit=..] [xmltv=..] [start=..] [numbering=..] [refresh=24]
one-clickRegisterSource MLB.tv \
  "$(one-clickChannelJson name=MLB.tv refresh= \
     url="http://$extensionURL/m3u" \
     xmltv="http://$extensionURL/epg")"
