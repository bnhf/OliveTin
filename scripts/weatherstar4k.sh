#!/bin/bash
# weatherstar4k.sh
# 2025.09.06

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$3" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
[[ "$5" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="$5"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0
cc4cHostPort="$6"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"TZ=$4"
)

customChannels() {
cat <<EOF
{
  "name": "WeatherStar4k",
  "type": "HLS",
  "source": "Text",
  "url": "",
  "text": "#EXTM3U\n\n#EXTINF:-1 channel-id=\"WS4KP\" tvg-logo=\"https://raw.githubusercontent.com/netbymatt/ws4kp/main/server/images/logos/logo192.png\",WeatherStar 4000+\nchrome://$cc4cHostPort/stream?url=http://$extensionURL",
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
  curl -s -o /dev/null http://$extensionURL && extensionUp=$(echo $?)
  [[ $extensionUp ]] && break || sleep 5
done

echo -e "\nJSON response from $dvr:"
curl -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/weatherstar4k
