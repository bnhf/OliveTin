#!/bin/bash
# ah4c.sh
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
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$5" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
[[ "${47}" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="${47}"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""
cdvrM3UName="${48}"
cdvrM3UNameNoExt="${cdvrM3UName%.m3u}"
dirsFile="/tmp/$extension.dirs"
ah4cContainer="${49}" && [[ "$ah4cContainer" == "#" ]] && ah4cContainer=""

envVars=(
"TAG=$2"
"CONTAINER_NAME=$extension$ah4cContainer"
"HOSTNAME=$extension$ah4cContainer"
"DOMAIN=$3"
"ADBS_PORT=$4"
"HOST_PORT=$5"
"SCRC_PORT=$6"
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
"CHANNELSIP=${28}"
"ALERT_SMTP_SERVER=${29}"
"ALERT_AUTH_SERVER=${30}"
"ALERT_EMAIL_FROM=${31}"
"ALERT_EMAIL_PASS=${32}"
"ALERT_EMAIL_TO=${33}"
"LIVETV_ATTEMPTS=${34}"
"CREATE_M3US=${35}"
"UPDATE_SCRIPTS=${36}"
"UPDATE_M3US=${37}"
"TZ=${38}"
"SPEED_MODE=${39}"
"KEEP_WATCHING=${40}"
"AUTOCROP_CHANNELS=${41}"
"LINKPI_HOSTNAME=${42}"
"LINKPI_USERNAME=${43}"
"LINKPI_PASSWORD=${44}"
"USER_SCRIPT=${45}"
"HOST_DIR=${46}"
"CDVR_STARTING_CHANNEL=${47}"
"CDVR_M3U_NAME=${48}"
"AH4C_CONTAINER=${49}"
)

synologyDirs=(
"${46}/ah4c$ah4cContainer/scripts"
"${46}/ah4c$ah4cContainer/m3u"
"${46}/ah4c$ah4cContainer/adb"
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

[[ $? == 1 ]] && exit 1

customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')

while true; do
  curl -s -o /dev/null http://$extensionURL && extensionUp=$(echo $?)
  [[ $extensionUp ]] && break || sleep 5
done

greenEcho "\nJSON response from $dvr:"
curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/ah4c$ah4cContainer-$cdvrM3UNameNoExt
