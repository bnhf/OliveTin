#!/bin/bash
# plex-for-channels.sh
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
regions=$5
[[ "$6" == "false" ]] && mjhCompatibility="" || mjhCompatibility="&compatibility=matthuisman"
[[ "$8" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="$8"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""
[[ -n $cdvrStartingChannel ]] && cdvrStartingChannel2=$((cdvrStartingChannel + 1000))
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0
dirsFile="/tmp/$extension.dirs"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"PORT=$4"
"HOST_DIR=$7"
)

synologyDirs=(
"$7/plex"
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
  "xmltv_url": "",
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
printf "%s\n" "${synologyDirs[@]}" > $dirsFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1

customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')
customChannelsJSON2=$(echo -n "$(customChannels2)" | tr -d '\n')

while true; do
  curl -s -o /dev/null "http://$extensionURL/plex/playlist.m3u?regions=$regions&gracenote=include$mjhCompatibility" && extensionUp=$(echo $?)
  [[ $extensionUp ]] && break || sleep 5
done

greenEcho "\nJSON response from $dvr:"
curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/PlexTV; echo
curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON2" http://$dvr/providers/m3u/sources/PlexTV-NoEPG
