#! /bin/bash

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$3" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"START_CHANNEL=$4"
"NUM_OF_CHANNELS=$5"
"PROXY_SEGMENTS=$6"
"PUID=$7"
"PGID=$8"
"PORT=$9"
"ESPNPLUS=${10}"
"ESPN=${11}"
"ESPN2=${12}"
"ESPN3=${13}"
"ESPNU=${14}"
"SEC=${15}"
"SECPLUS=${16}"
"ACCN=${17}"
"ACCNX=${18}"
"LONGHORN=${19}"
"ESPNEWS=${20}"
"ESPN_PPV=${21}"
"FOXSPORTS=${22}"
"FOXSPORTS_ALLOW_REPLAYS=${23}"
"MAX_RESOLUTION=${24}"
"FOX_ONLY_4K=${25}"
"PARAMOUNTPLUS=${26}"
"MLBTV=${27}"
"MLBTV_USER=${28}"
"MLBTV_PASS=${29}"
"MLBTV_ONLY_FREE=${30}"
"MSGPLUS=${31}"
"MSGPLUS_USER=${32}"
"MSGPLUS_PASS=${33}"
"HOST_VOLUME=${34}"
)

customChannels() {
cat <<EOF
{
  "name": "EPlusTV",
  "type": "HLS",
  "source": "URL",
  "url": "http://$extensionURL/channels.m3u",
  "text": "",
  "refresh": "",
  "limit": "",
  "satip": "",
  "numbering": "",
  "start_number": "",
  "logos": "",
  "xmltv_url": "http://$extensionURL/xmltv.xml",
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

curl -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/EPlusTV
