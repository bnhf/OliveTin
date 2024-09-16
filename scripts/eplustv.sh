#! /bin/bash

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$3" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
linearChannels=$6
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"START_CHANNEL=$4"
"NUM_OF_CHANNELS=$5"
"LINEAR_CHANNELS=$6"
"PROXY_SEGMENTS=$7"
"PUID=$8"
"PGID=$9"
"PORT=${10}"
"ESPNPLUS=${11}"
"ESPN=${12}"
"ESPN2=${13}"
"ESPN3=${14}"
"ESPNU=${15}"
"SEC=${16}"
"SECPLUS=${17}"
"ACCN=${18}"
"ACCNX=${19}"
"LONGHORN=${20}"
"ESPNEWS=${21}"
"ESPN_PPV=${22}"
"FOXSPORTS=${23}"
"FOXSPORTS_ALLOW_REPLAYS=${24}"
"MAX_RESOLUTION=${25}"
"FOX_ONLY_4K=${26}"
"PARAMOUNTPLUS=${27}"
"CBSSPORTSHQ=${28}"
"GOLAZO=${29}"
"NFLPLUS=${30}"
"NFLNETWORK=${31}"
"NFLREDZONE=${32}"
"B1GPLUS=${33}"
"B1GPLUS_USER=${34}"
"B1GPLUS_PASS=${35}"
"MSGPLUS=${36}"
"MSGPLUS_USER=${37}"
"MSGPLUS_PASS=${38}"
"FLOSPORTS=${39}"
"MTNWEST=${40}"
"MLBTV=${41}"
"MLBTV_USER=${42}"
"MLBTV_PASS=${43}"
"MLBTV_ONLY_FREE=${44}"
"HOST_VOLUME=${45}"
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

customChannels2() {
cat <<EOF
{
  "name": "EPlusTV-Linear",
  "type": "HLS",
  "source": "URL",
  "url": "http://$extensionURL/linear-channels.m3u",
  "text": "",
  "refresh": "",
  "limit": "",
  "satip": "",
  "numbering": "",
  "start_number": "",
  "logos": "",
  "xmltv_url": "http://$extensionURL/linear-xmltv.xml",
  "xmltv_refresh": "3600"
}
EOF
}

printf "%s\n" "${envVars[@]}" > $envFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1

customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')
customChannelsJSON2=$(echo -n "$(customChannels2)" | tr -d '\n')

while true; do
  curl -s -o /dev/null http://$extensionURL && extensionUp=$(echo $?)
  [[ $extensionUp ]] && break || sleep 5
done

curl -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/EPlusTV; echo
[[ $linearChannels == true ]] && curl -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON2" http://$dvr/providers/m3u/sources/EPlusTV-Linear
