#!/bin/bash
# one-click_delete.sh
# 2026.01.24

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
blueSpinner() { local t=$1 i=0 s='|/-\'; while (( i < t*5 )); do printf "\r\033[34m%c\033[0m" "${s:i++%4:1}"; sleep 0.2; done; printf "\r \r"; }
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"
configFile=/config/config.yaml
configTemp=/tmp/config.yaml

dvr="$1"
stackName=$(echo "$2" | awk -F'+' '{print $1}')
portainerHost="$PORTAINER_HOST"
portainerToken="$PORTAINER_TOKEN"
[[ -n $PORTAINER_PORT ]] && portainerPort="${4:-$PORTAINER_PORT}" || portainerPort="9443"
containerName=$(echo "$2" | awk -F'+' '{print $2}')
source1Name=$(echo "$2" | awk -F'+' '{print $3}')
  [[ $source1Name == none ]] && source1Name=""
[[ $source1Name =~ ^ah4c[0-9]*$ ]] && \
  dashM3U="$(curl -s "http://$dvr/devices" | jq -r --arg source "$source1Name" \
    '[..|objects|select(.Lineup?=="X-M3U")|.DeviceID|ltrimstr("M3U-")|select(startswith($source+"-"))|sub("^"+$source;"")][0]//empty')" \
  && [[ -n "$dashM3U" ]] && source1Name="${source1Name}${dashM3U}"
source2Name=$(echo "$2" | awk -F'+' '{print $4}')
  [[ $source2Name == none ]] && source2Name=""
[[ -n $PORTAINER_PORT ]] && portainerPort="$PORTAINER_PORT" || portainerPort="9443"
portainerName=${PORTAINER_NAME:-local}
portainerEnv=$(curl -s -k -H "X-API-Key: $portainerToken" "http://$portainerHost:9000/api/endpoints" | jq --arg portainerName "$portainerName" '.[] | select(.Name==$portainerName) | .Id') \
  && [[ -z $portainerEnv ]] && portainerEnv=$(curl -s -k -H "X-API-Key: $portainerToken" "https://$portainerHost:$portainerPort/api/endpoints" | jq --arg portainerName "$portainerName" '.[] | select(.Name==$portainerName) | .Id')
curl -s -o /dev/null http://$portainerHost:9000 \
  && portainerURL="http://$portainerHost:9000/api" \
  || portainerURL="https://$portainerHost:$portainerPort/api"

[[ -n $source1Name ]] && greenEcho "Deleting CDVR Custom Channels Source - $source1Name..." \
  && curl -s -X DELETE http://$dvr/providers/m3u/sources/$source1Name

[[ -n $source2Name ]] && greenEcho "\n\nDeleting CDVR Custom Channels Source - $source2Name..." \
  && curl -s -X DELETE http://$dvr/providers/m3u/sources/$source2Name

stackID=$(curl -s -k -X GET -H "X-API-Key: $portainerToken" "$portainerURL"/stacks | jq -r --arg name "$stackName" '.[] | select(.Name == $name) | .Id') \
  && greenEcho "\n\nPortainer reports the stack ID for $stackName as:" "$stackID"

greenEcho "\nStopping Portainer Stack ID $stackID:" \
  $(curl -s -k -X POST -H "X-API-Key: $portainerToken" "$portainerURL"/stacks/"$stackID"/stop?endpointId="$portainerEnv" | jq -r '.Name') \
  && blueSpinner 20

greenEcho "\nDeleting Portainer Stack ID $stackID..." \
  && curl -s -k -X DELETE -H "X-API-Key: $portainerToken" "$portainerURL"/stacks/"$stackID"?endpointId="$portainerEnv" | jq .

imageID=$(curl -s -k -X GET -H "X-API-Key: $portainerToken" "$portainerURL/endpoints/$portainerEnv/docker/images/json" | jq -r --arg name "$containerName" '.[] | select(any(.RepoTags[]; contains($name))) | .Id') \
  && greenEcho "\nPortainer reports the image ID for $stackName as:" "\n$imageID"

greenEcho "\nDeleting Portainer Image ID $imageID..." \
  && curl -s -k -X DELETE -H "X-API-Key: $portainerToken" "$portainerURL/endpoints/$portainerEnv/docker/images/$imageID" \
  | jq -r '
      ([.[] | .Untagged? | select(. != null and . != "")] | first // empty),
      ([.[] | .Deleted?  | select(. != null and . != "")] | first // empty)
    '

updateIcon() { sed "/#${stackName} icon/s|img src = .* width|img src = $purpleIcon width|" "$configFile" > "$configTemp" && cp "$configTemp" /config; }
[[ -n $imageID ]] && updateIcon

greenEcho "\nOne-Click Deletion of $stackName Completed!"
