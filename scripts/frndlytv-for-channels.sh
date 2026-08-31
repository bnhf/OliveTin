#!/bin/bash
# frndlytv-for-channels.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"
georelocationIP=$(emptyIfHash "$4")
cdvrStartingChannel="$7"
streamLimit="$8"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"
# one-clickCdvrNumbering <CDVR starting-channel arg; "#" if unset>
one-clickCdvrNumbering "$cdvrStartingChannel"
# the NoEPG source starts 100 channels above the first
[[ -n $cdvrStartingChannel ]] && cdvrStartingChannel2=$((cdvrStartingChannel + 100))

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"IP=$georelocationIP"
"USERNAME=$5"
"PASSWORD=$6"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp

# one-clickRegisterSource <CDVR source slug> <channel JSON>
# one-clickChannelJson name=.. url=.. [type=HLS] [source=URL] [text=..] [limit=..] [xmltv=..] [start=..]
one-clickRegisterSource FrndlyTV \
  "$(one-clickChannelJson name=FrndlyTV limit="$streamLimit" \
     url="http://$extensionURL/playlist.m3u8?gracenote=include")"
one-clickRegisterSource FrndlyTV-NoEPG \
  "$(one-clickChannelJson name=FrndlyTV-NoEPG limit="$streamLimit" start="$cdvrStartingChannel2" \
     url="http://$extensionURL/playlist.m3u8?gracenote=exclude" \
     xmltv="http://$extensionURL/epg.xml?gracenote=exclude")"
