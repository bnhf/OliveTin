#!/bin/bash
# tubi-for-channels.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"
cdvrStartingChannel="$7"
# "none" means no credentials
[[ "$5" == "none" ]] && tubiUser="" || tubiUser="$5"
[[ "$6" == "none" ]] && tubiPass="" || tubiPass="$6"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"
# one-clickCdvrNumbering <CDVR starting-channel arg; "#" if unset>
one-clickCdvrNumbering "$cdvrStartingChannel"
# the NoEPG source starts 300 channels above the first
[[ -n $cdvrStartingChannel ]] && cdvrStartingChannel2=$((cdvrStartingChannel + 300))

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"TUBI_PORT=$4"
"TUBI_USER=$tubiUser"
"TUBI_PASS=$tubiPass"
"CDVR_STARTING_CHANNEL=$7"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp

# one-clickRegisterSource <CDVR source slug> <channel JSON>
# one-clickChannelJson name=.. url=.. [type=HLS] [source=URL] [text=..] [limit=..] [xmltv=..] [start=..]
one-clickRegisterSource TubiTV \
  "$(one-clickChannelJson name="Tubi TV" \
     url="http://$extensionURL/tubi/playlist.m3u?gracenote=include")"
one-clickRegisterSource TubiTV-NoEPG \
  "$(one-clickChannelJson name="Tubi TV-NoEPG" start="$cdvrStartingChannel2" \
     url="http://$extensionURL/tubi/playlist.m3u?gracenote=exclude" \
     xmltv="http://$extensionURL/tubi/epg.xml")"
