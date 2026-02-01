#!/bin/bash
# multichannelview.sh
# 2026.01.18

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
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$4" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
[[ "$6" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="$6"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""
multiviewName="$7"
ch1="$8"; ch2="$9"; ch3="${10}"; ch4="${11}"
allChannelsM3U="$(curl -s http://media-server8:8089/devices/ANY/channels.m3u?format=ts&codec=copy)"
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0

channelIDs=($ch1 $ch2 $ch3 $ch4)
for channelID in "${channelIDs[@]}"; do
  channelName=$(echo "$allChannelsM3U" | awk -v channelID="$channelID" '
    index($0, "channel-id=\""channelID"\"") {
      match($0, /tvg-name="([^"]+)"/, m)
      if (m[1]) print m[1]
      exit
    }')
  channelIDsNames+=": ${channelID} ${channelName} "
done
multiviewChannels="Mosaic of $channelIDsNames"

envVars=(
"TAG=$2 # Add the tag like latest or test to the environment variables below."
"DEVICES=$3"
"HOST_PORT=$4 # Use the same port number the container is using, or optionally change it if the port is already in use on your host."
"CDVR_HOST=${dvr%%:*} # Hostname/IP of Channels DVR server."
"CDVR_PORT=${dvr##*:} # Port of Channels DVR server."
"CODEC=$5 # Use h264_qsv (hardware) or libx264 (software)."
)

customChannels() {
cat <<EOF
{
  "name": "Multichannel View",
  "type": "MPEG-TS",
  "source": "Text",
  "url": "",
  "text": "#EXTM3U\n\n#EXTINF:-1 tvg-id=\"MCH\" tvc-guide-placeholders=\"7200\" tvc-guide-title=\"$multiviewChannels\" tvc-guide-description=\"$multiviewChannels\" tvc-guide-art=\"https://i.postimg.cc/pdCcpxMM/Multichannel-View.png\" tvg-logo=\"https://i.postimg.cc/pdCcpxMM/Multichannel-View.png\" group-title=\"HD\",$multiviewName\nhttp://$extensionURL/combine?ch=$ch1&ch=$ch2&ch=$ch3&ch=$ch4",
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

greenEcho "\nJSON response from $dvr:"
curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/multichannelview
