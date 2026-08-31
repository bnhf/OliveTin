#!/bin/bash
# eplustv.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"
linearChannels="$6"
# "default" -> let the app choose its own base URL
[[ "$7" == "default" ]] && baseURL="" || baseURL="$7"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"START_CHANNEL=$4"
"NUM_OF_CHANNELS=$5"
"LINEAR_CHANNELS=$6"
"BASE_URL=$baseURL"
"PROXY_SEGMENTS=$8"
"PUID=$9"
"PGID=${10}"
"PORT=${11}"
"HOST_VOLUME=${12}"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp

# one-clickRegisterSource <CDVR source slug> <channel JSON>
# one-clickChannelJson name=.. url=.. [type=HLS] [source=URL] [text=..] [limit=..] [xmltv=..] [start=..] [numbering=..] [refresh=24]
one-clickRegisterSource EPlusTV \
  "$(one-clickChannelJson name=EPlusTV refresh= \
     url="http://$extensionURL/channels.m3u" \
     xmltv="http://$extensionURL/xmltv.xml")"

[[ $linearChannels == true ]] && one-clickRegisterSource EPlusTV-Linear \
  "$(one-clickChannelJson name=EPlusTV-Linear refresh= \
     url="http://$extensionURL/linear-channels.m3u" \
     xmltv="http://$extensionURL/linear-xmltv.xml")" || true
