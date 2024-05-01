#! /bin/bash

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$5" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
[[ "${30}" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="${30}"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""
cdvrM3UName="${31}"
cdvrM3UNameNoExt="${cdvrM3UName%.m3u}"

envVars=(
"TAG=$2"
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
"STREAMER_APP=${17}"
"CHANNELSIP=${18}"
"ALERT_SMTP_SERVER=${19}"
"ALERT_AUTH_SERVER=${20}"
"ALERT_EMAIL_FROM=${21}"
"ALERT_EMAIL_PASS=${22}"
"ALERT_EMAIL_TO=${23}"
"LIVETV_ATTEMPTS=${24}"
"CREATE_M3US=${25}"
"UPDATE_SCRIPTS=${26}"
"UPDATE_M3US=${27}"
"TZ=${28}"
"HOST_DIR=${29}"
"CDVR_STARTING_CHANNEL=${30}"
"CDVR_M3U_NAME=${31}"
)

customChannels() {
cat <<EOF
{
  "name": "ah4c - $cdvrM3UNameNoExt",
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

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1

customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')

sleep 8

curl -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/ah4c-$cdvrM3UNameNoExt
