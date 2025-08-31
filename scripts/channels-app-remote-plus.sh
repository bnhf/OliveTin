#!/bin/bash
# channels-app-remote-plus.sh
# 2025.07.10

set -x

extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
dvrs=($CHANNELS_DVR $CHANNELS_DVR_ALTERNATES)
channelsDVRs=$(IFS=,; echo "${dvrs[*]}")

envVars=(
"TAG=$1 # Add the tag like latest or test to the environment variables below."
"HOST_PORT=$2 # The container port number (to the right of the colon) needs to be left as is. Set the environment variable to the same, or change it if there's a conflict."
"CHANNELS_DVR_SERVERS=$channelsDVRs # A comma separated list of Channels DVRs by ip:port or hostname:port"
)

printf "%s\n" "${envVars[@]}" > $envFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
