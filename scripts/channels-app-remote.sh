#!/bin/bash
# channels-app-remote.sh
# 2025.06.21

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
channelsAppClients="$(curl -s http://$dvr/dvr/clients/info | jq -r '[.[] | "\(.hostname):\(.local_ip)"] | join(",")')"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"CHANNELS_APP_CLIENTS=$channelsAppClients"
)

printf "%s\n" "${envVars[@]}" > $envFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
