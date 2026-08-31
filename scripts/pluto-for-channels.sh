#!/bin/bash
# pluto-for-channels.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"
cdvrStartingChannel="$7"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"
# one-clickCdvrNumbering <CDVR starting-channel arg; "#" if unset>
one-clickCdvrNumbering "$cdvrStartingChannel"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"PLUTO_USERNAME=$4"
"PLUTO_PASSWORD=$5"
"PLUTO_CODE=$6"
"CDVR_STARTING_CHANNEL=$7"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp

# one-clickRegisterSource <CDVR source slug> <channel JSON>
# one-clickChannelJson name=.. url=.. [type=HLS] [source=URL] [text=..] [limit=..] [xmltv=..] [start=..]
one-clickRegisterSource PlutoTV \
  "$(one-clickChannelJson name="Pluto TV" \
     url="http://$extensionURL/pluto/all/playlist.m3u" \
     xmltv="http://$extensionURL/pluto/epg/all/epg-all.xml")"
