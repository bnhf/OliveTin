#!/bin/bash
# prismcast.sh
# 2026.01.26

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
blueSpinner() { local t=$1 i=0 s='|/-\'; while (( i < t*5 )); do printf "\r\033[34m%c\033[0m" "${s:i++%4:1}"; sleep 0.2; done; printf "\r \r"; }
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$4" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
[[ "$7" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="$7"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""

envVars=(
"TAG=$2"
"DOMAIN=$3"
"HOST_PORT=$4"
"HOST_VNC_PORT=$5"
"HOST_NOVNC_PORT=$6"
"DISPLAY_NUM=99"
"SCREEN_WIDTH=1920"
"SCREEN_HEIGHT=1080"
"SCREEN_DEPTH=24"
"CDVR_STARTING_CHANNEL=$7"
)

customChannels() {
cat <<EOF
{
  "name": "PrismCast",
  "type": "HLS",
  "source": "URL",
  "url": "http://$extensionURL/playlist",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$cdvrIgnoreM3UNumbers",
  "start_number": "$cdvrStartingChannel",
  "logos": "",
  "xmltv_url": "",
  "xmltv_refresh": "3600"
}
EOF
}

printf "%s\n" "${envVars[@]}" > $envFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1

customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')

while true; do
  curl -s -o /dev/null $extensionURL && extensionUp=$(echo $?)
  [[ $extensionUp ]] && break || blueSpinner 5
done

greenEcho "\nJSON response from $dvr:"
curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/prismcast; echo
