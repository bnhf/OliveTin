#!/bin/bash
# portainervolume.sh
# 2025.03.29

set -x

volumeName="$1"
serverCIFS="$2"
serverShare="$3"
shareUsername="$4"
sharePassword="$5"

[[ -z $PORTAINER_HOST ]] && portainerHost="${CHANNELS_DVR%%:*}" || portainerHost="$PORTAINER_HOST"

portainerHttpPort=$(docker inspect portainer | jq -r '.[0].NetworkSettings.Ports["9000/tcp"][0].HostPort')
portainerHttpsPort=$(docker inspect portainer | jq -r '.[0].NetworkSettings.Ports["9443/tcp"][0].HostPort')
[[ -n $portainerHttpPort ]] && portainerURL="http://$portainerHost:$portainerHttpPort" \
  || portainerURL="https://$portainerHost:$portainerHttpsPort"

[[ -f /config/olivetin.token ]] && portainerToken="$(cat /config/olivetin.token)" || portainerToken="$PORTAINER_TOKEN"
[[ -f /config/portainer_env.id ]] && portainerEnv="$(cat /config/portainer_env.id)"
[[ -z $portainerEnv ]] && portainerEnv=$(curl -s -k -H "X-API-Key: $portainerToken" "$portainerURL/api/endpoints" | jq '.[] | select(.Name=="local") | .Id') 

volumeJSON=$(cat <<EOF
{
  "Name": "$volumeName",
  "Driver": "local",
  "DriverOpts": {
    "type": "cifs",
    "device": "//$serverCIFS/$serverShare",
    "o": "addr=$serverCIFS,username=$shareUsername,password=$sharePassword,vers=2.0"
  }
}
EOF
)

curl -k -X POST "$portainerURL/api/endpoints/$portainerEnv/docker/volumes/create" \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $portainerToken" \
        -d "$volumeJSON"

echo -e "\nCurrently configued Docker/Portainer Volumes:"
docker volume ls
