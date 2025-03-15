#! /bin/bash

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$3" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
regions=$5
[[ "$6" == "false" ]] && mjhCompatibility="" || mjhCompatibility="&compatibility=matthuisman"
[[ "$8" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="$8"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""
[[ -n $cdvrStartingChannel ]] && cdvrStartingChannel2=$((cdvrStartingChannel + 1000))
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"PORT=$4"
"HOST_DIR=$7"
)

customChannels() {
cat <<EOF
{
  "name": "Plex TV",
  "type": "HLS",
  "source": "URL",
  "url": "http://$extensionURL/plex/playlist.m3u?regions=$regions&gracenote=include$mjhCompatibility",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$cdvrIgnoreM3UNumbers",
  "start_number": "$cdvrStartingChannel",
  "logos": "",
  "xmltv_url": "http://$extensionURL/plex/epg.xml",
  "xmltv_refresh": "3600"
}
EOF
}

customChannels2() {
cat <<EOF
{
  "name": "Plex TV-NoEPG",
  "type": "HLS",
  "source": "URL",
  "url": "http://$extensionURL/plex/playlist.m3u?regions=$regions&gracenote=exclude$mjhCompatibility",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$cdvrIgnoreM3UNumbers",
  "start_number": "$cdvrStartingChannel2",
  "logos": "",
  "xmltv_url": "http://$extensionURL/plex/epg.xml",
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
  curl -s -o /dev/null $extensionURL && extensionUp=$(echo $?)
  [[ $extensionUp ]] && break || sleep 5
done

curl -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/PlexTV; echo
curl -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON2" http://$dvr/providers/m3u/sources/PlexTV-NoEPG
