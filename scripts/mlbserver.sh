#!/bin/bash
# mlbserver.sh
# 2026.01.17

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$3" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
[[ "${10}" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="${10}"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0
dirsFile="/tmp/$extension.dirs"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"TZ=$4"
"DATA_DIRECTORY=$5"
"ACCOUNT_USERNAME=$6"
"ACCOUNT_PASSWORD=$7"
"FAV_TEAMS=$8"
"ZIP_CODE=0"
"HOST_DIR=$9"
)

synologyDirs=(
"$9/mlbserver"
)

customChannels() {
cat <<EOF
{
  "name": "mlbserver",
  "type": "HLS",
  "source": "URL",
  "url": "http://$extensionURL/channels.m3u?mediaType=Video&resolution=best",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$cdvrIgnoreM3UNumbers",
  "start_number": "$cdvrStartingChannel",
  "logos": "",
  "xmltv_url": "http://$extensionURL/guide.xml?mediaType=Video&includeTeamsInTitles=channels&offAir=channels",
  "xmltv_refresh": "3600"
}
EOF
}

printf "%s\n" "${envVars[@]}" > $envFile
printf "%s\n" "${synologyDirs[@]}" > $dirsFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1

customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')

while true; do
  curl -s -o /dev/null http://$extensionURL && extensionUp=$(echo $?)
  [[ $extensionUp ]] && break || sleep 5
done

greenEcho "\nJSON response from $dvr:"
curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/mlbserver
