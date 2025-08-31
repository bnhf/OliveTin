#!/bin/bash
# multi4channels.sh
# 2025.06.29

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$3" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
cdvrChannelNumber="$5"
rtpPort="$8"
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"WEB_PAGE_PORT=$4"
"CDVR_HOST=${dvr%%:*}"
"CDVR_PORT=${dvr##*:}"
"CDVR_CHNLNUM=$5"
"OUTPUT_FPS=$6"
"RTP_HOST=$7"
"RTP_PORT=$8"
"HOST_VOLUME=$9"
)

customChannels() {
cat <<EOF
{
  "name": "Multi4Channels",
  "type": "HLS",
  "source": "Text",
  "url": "",
  "text": "#EXTM3U\n\n#EXTINF:0 channel-id=\"M4C\" tvg-id=\"$cdvrChannelNumber\" tvg-chno=\"$cdvrChannelNumber\" tvc-guide-placeholders=\"7200\" tvc-guide-title=\"Start a Stream At $extensionURL.\" tvc-guide-description=\"Visit Multi4Channels Web Page to Start a Stream ($extensionURL).\" tvc-guide-art=\"https://i.postimg.cc/xCy2v22X/IMG-3254.png\" tvg-logo=\"https://i.postimg.cc/xCy2v22X/IMG-3254.png\" tvc-guide-stationid=\"\" tvg-name=\"Multi4Channels\" group-title=\"HD\",M4C\nudp://0.0.0.0:$rtpPort",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "",
  "start_number": "",
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
curl -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/multi4channels
