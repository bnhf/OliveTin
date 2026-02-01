#!/bin/bash
# tubi-for-channels.sh
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
[[ "$5" == "none" ]] && tubiUser="" || tubiUser="$5"
[[ "$6" == "none" ]] && tubiPass="" || tubiPass="$6"
[[ "$7" == "#" ]] && cdvrStartingChannel="" || cdvrStartingChannel="$7"
[[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers="ignore" || cdvrIgnoreM3UNumbers=""
[[ -n $cdvrStartingChannel ]] && cdvrStartingChannel2=$((cdvrStartingChannel + 300))
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"TUBI_PORT=$4"
"TUBI_USER=$tubiUser"
"TUBI_PASS=$tubiPass"
"CDVR_STARTING_CHANNEL=$7"
)

customChannels() {
cat <<EOF
{
  "name": "Tubi TV",
  "type": "HLS",
  "source": "URL",
  "url": "http://$extensionURL/tubi/playlist.m3u?gracenote=include",
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
  "name": "Tubi TV-NoEPG",
  "type": "HLS",
  "source": "URL",
  "url": "http://$extensionURL/tubi/playlist.m3u?gracenote=exclude",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$cdvrIgnoreM3UNumbers",
  "start_number": "$cdvrStartingChannel2",
  "logos": "",
  "xmltv_url": "http://$extensionURL/tubi/epg.xml",
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

greenEcho "\nJSON response from $dvr:"
curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/TubiTV; echo
curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON2" http://$dvr/providers/m3u/sources/TubiTV-NoEPG
