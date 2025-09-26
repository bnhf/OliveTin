#!/bin/bash
# pluto-for-channels2.sh
# 2025.09.20

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$3" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
[[ "$7" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="$7"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"PLUTO_USERNAME=$4"
"PLUTO_PASSWORD=$5"
"PLUTO_CODE=$6"
"CDVR_STARTING_CHANNEL=$7"
)

customChannels() {
cat <<EOF
{
  "name": "Pluto TV 2",
  "type": "HLS",
  "source": "URL",
  "url": "http://$extensionURL/pluto/all/playlist.m3u",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$cdvrIgnoreM3UNumbers",
  "start_number": "$cdvrStartingChannel",
  "logos": "",
  "xmltv_url": "http://$extensionURL/pluto/epg/all/epg-all.xml",
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
  curl -s -o /dev/null http://$extensionURL && extensionUp=$(echo $?)
  [[ $extensionUp ]] && break || sleep 5
done

echo -e "\nJSON response from $dvr:"
curl -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/PlutoTV2
