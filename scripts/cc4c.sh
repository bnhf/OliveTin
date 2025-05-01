#!/bin/bash
# cc4c.sh
# 2025.04.13

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$3" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
[[ "${16}" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="${16}"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""
[[ "${17}" == "none" ]] && m3uFile="" || m3uFile="${17}"
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"CC4C_PORT=$4"
"HOST_VNC_PORT=$5"
"VIDEO_BITRATE=$6"
"AUDIO_BITRATE=$7"
"FRAMERATE=$8"
"VIDEO_WIDTH=$9"
"VIDEO_HEIGHT=${10}"
"VIDEO_CODEC=${11}"
"AUDIO_CODEC=${12}"
"TZ=${13}"
"HOST_VOLUME=${14}"
"DEVICES=${15}"
)

[[ -n $m3uFile ]] && textM3U=$(awk 'NR > 2' /config/cc4c_"$m3uFile".m3u | sed "s/localhost:5589/$extensionURL/g" | sed ':a;N;$!ba;s/\n/\\n/g')

customChannels() {
cat <<EOF
{
  "name": "cc4c",
  "type": "HLS",
  "source": "Text",
  "url": "",
  "text": "#EXTM3U\n\n#EXTINF:-1 channel-id=\"weatherscan\",Weatherscan\nchrome://$extensionURL/stream?url=https://v2.weatherscan.net\n\n$textM3U",
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
curl -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/cc4c
