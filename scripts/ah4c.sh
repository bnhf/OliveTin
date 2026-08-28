#!/bin/bash
# ah4c.sh
# 2026.08.28

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }
redEcho() { echo -e "\033[0;31m$1\033[0m ${*:2}"; }
blueSpinner() { local t=$1 i=0 s='|/-\'; while (( i < t*5 )); do printf "\r\033[34m%c\033[0m" "${s:i++%4:1}"; sleep 0.2; done; printf "\r \r"; }

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$6" || { redEcho "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; redEcho "\nFinished -- with errors"; exit 1; }
[[ "${58}" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="${58}"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""
cdvrM3UName="${59}"
cdvrM3UNameNoExt="${cdvrM3UName%.m3u}"
dirsFile="/tmp/$extension.dirs"
ah4cContainer="${60}" && [[ "$ah4cContainer" == "#" ]] && ah4cContainer=""
hostDir="${57}"

if curl -s -o /dev/null http://$extensionURL; then
  greenEcho "\n$extensionURL already in use -- assuming $extension$ah4cContainer is already running. Skipping stack creation."
  greenEcho "\nFinished -- no errors registered"
  exit 0
fi

envVars=(
"TAG=$2"
"CONTAINER_NAME=$extension$ah4cContainer"
"HOSTNAME=$extension$ah4cContainer"
"DOMAIN=$3"
"DOCKER_RUNTIME=$4"
"GPU_DEVICE=$5"
"HOST_PORT=$6"
"IPADDRESS=$7"
"NUMBER_TUNERS=$8"
"TUNER1_IP=$9"
"ENCODER1_URL=${10}"
"TUNER2_IP=${11}"
"ENCODER2_URL=${12}"
"TUNER3_IP=${13}"
"ENCODER3_URL=${14}"
"TUNER4_IP=${15}"
"ENCODER4_URL=${16}"
"TUNER5_IP=${17}"
"ENCODER5_URL=${18}"
"TUNER6_IP=${19}"
"ENCODER6_URL=${20}"
"TUNER7_IP=${21}"
"ENCODER7_URL=${22}"
"TUNER8_IP=${23}"
"ENCODER8_URL=${24}"
"TUNER9_IP=${25}"
"ENCODER9_URL=${26}"
"STREAMER_APP=${27}"
"PYATV=${28}"
"CHANNELSIP=${29}"
"ALERT_SMTP_SERVER=${30}"
"ALERT_AUTH_SERVER=${31}"
"ALERT_EMAIL_FROM=${32}"
"ALERT_EMAIL_PASS=${33}"
"ALERT_EMAIL_TO=${34}"
"ALERT_WEBHOOK_URL=${35}"
"LIVETV_ATTEMPTS=${36}"
"CREATE_M3US=${37}"
"UPDATE_SCRIPTS=${38}"
"UPDATE_M3US=${39}"
"TZ=${40}"
"SPEED_MODE=${41}"
"KEEP_WATCHING=${42}"
"AUTOCROP_CHANNELS=${43}"
"LINKPI_HOSTNAME=${44}"
"LINKPI_USERNAME=${45}"
"LINKPI_PASSWORD=${46}"
"USER_SCRIPT=${47}"
"NULL_FRAME_INSERTION=${48}"
"PLAYBACK_DETECTION=${49}"
"PLAYBACK_STATIC_TIMEOUT=${50}"
"PLAYBACK_DELAY=${51}"
"PREROLL_FILE=${52}"
"ENCODER_CODEC=${53}"
"HEARTBEAT_INTERVAL=${54}"
"NVIDIA_VISIBLE_DEVICES=${55}"
"NVIDIA_DRIVER_CAPABILITIES=${56}"
"HOST_DIR=${57}"
"CDVR_STARTING_CHANNEL=${58}"
"CDVR_M3U_NAME=${59}"
"AH4C_CONTAINER=${60}"
)

synologyDirs=(
"${57}/ah4c$ah4cContainer/scripts"
"${57}/ah4c$ah4cContainer/m3u"
"${57}/ah4c$ah4cContainer/adb"
)

customChannels() {
cat <<EOF
{
  "name": "ah4c$ah4cContainer - $cdvrM3UNameNoExt",
  "type": "MPEG-TS",
  "source": "URL",
  "url": "http://$extensionURL/m3u/$cdvrM3UName",
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

printf "%s\n" "${envVars[@]}" > $envFile
printf "%s\n" "${synologyDirs[@]}" > $dirsFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

if [[ $? == 1 ]]; then
  redEcho "\nFinished -- with errors"
  exit 1
fi

customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')

greenEcho "\nWaiting for $extension$ah4cContainer ($extensionURL) to respond..."
while true; do
  curl -s -o /dev/null http://$extensionURL && extensionUp=$(echo $?)
  [[ $extensionUp ]] && break || blueSpinner 5
done

m3uURL="http://$extensionURL/m3u/$cdvrM3UName"
greenEcho "\nVerifying CDVR_M3U_NAME \"$cdvrM3UName\" is readable at $m3uURL..."
for attempt in {1..10}; do
  m3uFirstLine=$(curl -s "$m3uURL" | head -c 7)
  [[ "$m3uFirstLine" == "#EXTM3U" ]] && break
  blueSpinner 3
done

if [[ "$m3uFirstLine" != "#EXTM3U" ]]; then
  redEcho "\nERROR: CDVR_M3U_NAME \"$cdvrM3UName\" did not return a valid M3U at $m3uURL."
  echo "Confirm the file exists at $hostDir/ah4c$ah4cContainer/m3u/$cdvrM3UName."
  echo "Skipping CDVR Custom Channel creation."
  echo "The ah4c$ah4cContainer stack was already created in Portainer above -- re-running this action as-is will fail there with a name conflict."
  echo "Either fix the file in place, or stop and delete the ah4c$ah4cContainer stack in Portainer first before re-running with a corrected CDVR_M3U_NAME."
  redEcho "\nFinished -- with errors"
  exit 1
fi

greenEcho "M3U verified."

greenEcho "\nJSON response from $dvr:"
curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/ah4c$ah4cContainer-$cdvrM3UNameNoExt
curlExit=$?

if [[ $curlExit -ne 0 ]]; then
  redEcho "\nFinished -- with errors"
  exit 1
fi

greenEcho "\nFinished -- no errors registered"
