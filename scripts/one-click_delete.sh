#!/bin/bash
# one-click_delete.sh
# 2025.09.13

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

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
#[[ -n $PORTAINER_ENV ]] && portainerEnv="$PORTAINER_ENV" || portainerEnv="2"
portainerEnv=$(curl -s -k -H "X-API-Key: $portainerToken" "http://$portainerHost:9000/api/endpoints" | jq '.[] | select(.Name=="local") | .Id') \
  && [[ -z $portainerEnv ]] && portainerEnv=$(curl -s -k -H "X-API-Key: $portainerToken" "https://$portainerHost:$portainerPort/api/endpoints" | jq '.[] | select(.Name=="local") | .Id')
curl -s -o /dev/null http://$portainerHost:9000 \
  && portainerURL="http://$portainerHost:9000/api" \
  || portainerURL="https://$portainerHost:$portainerPort/api"

[[ -n $source1Name ]] && echo "Deleting CDVR Custom Channels Source - $source1Name..." \
  && curl -s -X DELETE http://$dvr/providers/m3u/sources/$source1Name

[[ -n $source2Name ]] && echo -e "\n\nDeleting CDVR Custom Channels Source - $source2Name..." \
  && curl -X DELETE http://$dvr/providers/m3u/sources/$source2Name

stackID=$(curl -s -k -X GET -H "X-API-Key: $portainerToken" "$portainerURL"/stacks | jq -r --arg name "$stackName" '.[] | select(.Name == $name) | .Id') \
  && echo -e "\n\nPortainer reports the stack ID for $stackName as $stackID..."

echo -e "\nStopping Portainer Stack ID $stackID..." \
  && curl -s -k -X POST -H "X-API-Key: $portainerToken" "$portainerURL"/stacks/"$stackID"/stop?endpointId="$portainerEnv" \
  && sleep 20

echo -e "\nDeleting Portainer Stack ID $stackID..." \
  && curl -s -k -X DELETE -H "X-API-Key: $portainerToken" "$portainerURL"/stacks/"$stackID"?endpointId="$portainerEnv"

imageID=$(curl -s -k -X GET -H "X-API-Key: $portainerToken" "$portainerURL/endpoints/$portainerEnv/docker/images/json" | jq -r --arg name "$containerName" '.[] | select(any(.RepoTags[]; contains($name))) | .Id') \
  && echo -e "\nPortainer reports the image ID for $stackName as $imageID..."

echo -e "\nDeleting Portainer Stack ID $imageID..." \
  && curl -s -k -X DELETE -H "X-API-Key: $portainerToken" "$portainerURL"/endpoints/$portainerEnv/docker/images/$imageID
