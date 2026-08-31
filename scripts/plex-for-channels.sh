#!/bin/bash
# plex-for-channels.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"
regions="$5"
hostDir="$7"
cdvrStartingChannel="$8"
# "false" disables the matthuisman compatibility flag
[[ "$6" == "false" ]] && mjhCompatibility="" || mjhCompatibility="&compatibility=matthuisman"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"
# one-clickCdvrNumbering <CDVR starting-channel arg; "#" if unset>
one-clickCdvrNumbering "$cdvrStartingChannel"
# the NoEPG source starts 1000 channels above the first
[[ -n $cdvrStartingChannel ]] && cdvrStartingChannel2=$((cdvrStartingChannel + 1000))

playlistURL="http://$extensionURL/plex/playlist.m3u?regions=$regions&gracenote=include$mjhCompatibility"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"PORT=$4"
"HOST_DIR=$7"
)

synologyDirs=(
"$hostDir/plex"
)

# one-clickCreateStack -- no args; uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp "$playlistURL"

# one-clickRegisterSource <CDVR source slug> <channel JSON>
# one-clickChannelJson name=.. url=.. [type=HLS] [source=URL] [text=..] [limit=..] [xmltv=..] [start=..]
one-clickRegisterSource PlexTV \
  "$(one-clickChannelJson name="Plex TV" url="$playlistURL")"
one-clickRegisterSource PlexTV-NoEPG \
  "$(one-clickChannelJson name="Plex TV-NoEPG" start="$cdvrStartingChannel2" \
     url="http://$extensionURL/plex/playlist.m3u?regions=$regions&gracenote=exclude$mjhCompatibility" \
     xmltv="http://$extensionURL/plex/epg.xml")"
