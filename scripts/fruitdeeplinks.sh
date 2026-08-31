#!/bin/bash
# fruitdeeplinks.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
channelsDVRHost="${dvr%%:*}"
channelsDVRPort="${dvr##*:}"
hostPort="$4"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$2"
"DOMAIN=$3"
"FRUIT_HOST_PORT=$4"
"TZ=$5"
"SERVER_URL=$6"
"CC_SERVER=$7"
"CC_PORT=$8"
"CHANNELS_DVR_IP=$channelsDVRHost"
"CDVR_SERVER_PORT=$channelsDVRPort"
"CHANNELS_SOURCE_NAME=FruitDeepLinks"
"FRUIT_LANES=$9"
"CHANNELS_DVR_PATH=${10}"
"AUTO_REFRESH_ENABLED=${11}"
"AUTO_REFRESH_TIME=${12}"
"HOST_DIR=${13}"
"FRUIT_LANE_START_CH=${14}"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack
