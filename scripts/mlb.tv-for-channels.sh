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
"APP_URL=$4"
"LOG_LEVEL=$5"
"MLB_USERNAME=$6"
"MLB_PASSWORD=$7"
"MLB_BITRATE=$8"
"MLB_PLAYLIST_FIRST_CHANNEL=$9"
"MLB_TEAM_ORDER=${10}"
"MLB_TIMEZONE=${11}"
"MLB_SHOW_TV_FEEDS=${12}"
"MLB_SHOW_RADIO_FEEDS=${13}"
"HOST_VOLUME_APP=${14}"
"HOST_VOLUME_LOGS=${15}"
)

customChannels() {
cat <<EOF
{
  "name": "MLB.tv",
  "type": "HLS",
  "source": "URL",
  "url": "http://$extensionURL/m3u",
  "text": "",
  "refresh": "",
  "limit": "",
  "satip": "",
  "numbering": "",
  "start_number": "",
  "logos": "",
  "xmltv_url": "http://$extensionURL/epg",
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
curl -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/MLB.tv
