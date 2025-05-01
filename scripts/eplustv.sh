#!/bin/bash
# eplustv.sh
# 2025.04.01

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$3" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
linearChannels=$6
[[ "$7" == "default" ]] && baseURL="" || baseURL="$7"
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"START_CHANNEL=$4"
"NUM_OF_CHANNELS=$5"
"LINEAR_CHANNELS=$6"
"BASE_URL=$baseURL"
"PROXY_SEGMENTS=$8"
"PUID=$9"
"PGID=${10}"
"PORT=${11}"
"HOST_VOLUME=${12}"
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
