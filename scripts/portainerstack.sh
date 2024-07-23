#!/bin/bash

set -x

stackName="$1"
portainerHost="$PORTAINER_HOST"
curl -s -o /dev/null http://$portainerHost:9000 \
  && portainerURL="http://$portainerHost:9000/api/stacks?type=2&method=string&endpointId=2" \
  || portainerURL="https://$portainerHost:9443/api/stacks?type=2&method=string&endpointId=2"
portainerToken="$PORTAINER_TOKEN"
cp /config/$stackName.yaml /tmp
stackFile="/tmp/$stackName.yaml"
envFile="/tmp/$stackName.env"

dockerVolume=$(grep 'DVR_SHARE=' $envFile | grep -v '/' | awk -F'=' '{print $2}')
volumeExternal=$(grep 'VOL_EXTERNAL=' $envFile | grep -v '#' | awk -F'=' '{print $2}')
volumeName=$(grep 'VOL_NAME=' $envFile | grep -v '#' | awk -F'=' '{print $2}')

if [[ -n $dockerVolume ]]; then
  sed -i 's/#volumes:/volumes:/' $stackFile
  sed -i 's/#channels-dvr:/'$dockerVolume':/' $stackFile
  [[ -n $volumeExternal ]] && sed -i 's/#external:/external:/' $stackFile
  [[ -n $volumeName ]] && sed -i 's/#name:/name:/' $stackFile
fi

stackContent=$(sed 's/\\/\\\\/g' "$stackFile" | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
stackEnvVars="["

while IFS='=' read -r key value
do
  stackEnvVars="${stackEnvVars}{\"name\": \"$key\", \"value\": \"$value\"},"
done < "$envFile"

stackEnvVars="${stackEnvVars%,}]"

stackJSON=$(cat <<EOF
{
  "Name": "$stackName",
  "SwarmID": "",
  "StackFileContent": "$stackContent",
  "Env": $stackEnvVars
}
EOF
)

echo "JSON response from $portainerURL:"
portainerResponse=$(curl -k -X POST -H "Content-Type: application/json" -H "X-API-Key: ${portainerToken}" -d "$stackJSON" "$portainerURL")

[[ -z $portainerResponse ]] && exit 1

echo $portainerResponse
echo "$portainerResponse" | jq -e '.Id != null' && exit 0 || exit 1
