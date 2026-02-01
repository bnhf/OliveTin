#!/bin/bash
# espn4cc4c.sh
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
[[ -n $PORTAINER_HOST ]] && extensionURL="$PORTAINER_HOST:$4" || { echo "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
[[ "${15}" == "#" ]] && cc4cStartingChannel="" || cc4cStartingChannel="${15}"
[[ -n $cc4cStartingChannel ]] && cc4cIgnoreM3UNumbers="ignore" || cc4cIgnoreM3UNumbers=""
[[ "${14}" == "false" ]] && cc4cSource="" || cc4cSource="${14}"
[[ "${17}" == "#" ]] && ch4cStartingChannel="" || ch4cStartingChannel="${17}"
[[ -n $ch4cStartingChannel ]] && ch4cIgnoreM3UNumbers="ignore" || ch4cIgnoreM3UNumbers=""
[[ "${16}" == "false" ]] && ch4cSource="" || ch4cSource="${16}"
curl -s -o /dev/null http://$extensionURL && echo "$extensionURL already in use" && exit 0

envVars=(
"TAG=$2"
"DOMAIN=$3"
"HOST_PORT=$4"
"TZ=$5"
"VC_RESOLVER_BASE_URL=$6"
"CC_HOST=$7"
"CC_PORT=$8"
"CH4C_HOST=$9"
"CH4C_PORT=${10}"
"LANES=${11}"
"FILTER_EXCLUDE_REAIR=${12}"
"HOST_DIR=${13}"
)

customChannels() {
cat <<EOF
{
  "name": "ESPN4cc4c",
  "type": "MPEG-TS",
  "source": "URL",
  "url": "http://$extensionURL/out/playlist.m3u",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$cc4cIgnoreM3UNumbers",
  "start_number": "$cc4cStartingChannel",
  "logos": "",
  "xmltv_url": "http://$extensionURL/out/epg.xml",
  "xmltv_refresh": "3600"
}
EOF
}

customChannels2() {
cat <<EOF
{
  "name": "ESPN4ch4c",
  "type": "MPEG-TS",
  "source": "URL",
  "url": "http://$extensionURL/out/playlist.ch4c.m3u",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$ch4cIgnoreM3UNumbers",
  "start_number": "$ch4cStartingChannel",
  "logos": "",
  "xmltv_url": "http://$extensionURL/out/epg.xml",
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

[[ $cc4cSource ]] && greenEcho "\nJSON response from $dvr:" \
  && curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/ESPN4cc4c \
  || true

[[ $ch4cSource ]] && greenEcho "\nJSON response from $dvr:" \
  && curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON2" http://$dvr/providers/m3u/sources/ESPN4ch4c \
  || true
