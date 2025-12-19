#!/bin/bash
# fruitdeeplinks.sh
# 2025.12.18

set -x

dvr="$1"
  channelsDVRHost="${dvr%%:*}"
  channelsDVRPort="${dvr##*:}"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$4" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0

envVars=(
"TAG=$2"
"DOMAIN=$3"
"FRUIT_HOST_PORT=$4"
"TZ=$5"
"SERVER_URL=$6"
"CHANNELS_DVR_IP=$channelsDVRHost"
"CHANNELS_SOURCE_NAME=FruitDeepLinks"
"FRUIT_LANES=$7"
"HOST_DIR=$8"
"FRUIT_LANE_START_CH=$9"
)

printf "%s\n" "${envVars[@]}" > $envFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1
