#!/bin/bash
# portainerstack.sh
# 2025.02.21

set -x

stackName="$1"
portainerHost="$PORTAINER_HOST"
[[ -n $PORTAINER_PORT ]] && portainerPort="$PORTAINER_PORT" || portainerPort="9443"
[[ -n $PORTAINER_ENV ]] && portainerEnv="$PORTAINER_ENV" || portainerEnv="2"
#curl -s -o /dev/null http://$portainerHost:9000 \
  #&& portainerURL="http://$portainerHost:9000/api/stacks?type=2&method=string&endpointId=2" \
  #|| portainerURL="https://$portainerHost:$portainerPort/api/stacks?type=2&method=string&endpointId=2"
curl -s -o /dev/null http://$portainerHost:9000 \
  && portainerURL="http://$portainerHost:9000/api/stacks/create/standalone/string?endpointId=$portainerEnv" \
  || portainerURL="https://$portainerHost:$portainerPort/api/stacks/create/standalone/string?endpointId=$portainerEnv"
portainerToken="$PORTAINER_TOKEN"
cp /config/$stackName.yaml /tmp
stackFile="/tmp/$stackName.yaml"
envFile="/tmp/$stackName.env"

dockerVolume=$(grep 'DVR_SHARE=' $envFile | grep -v '/' | awk -F'=' '{print $2}')
volumeExternal=$(grep 'VOL_EXTERNAL=' $envFile | grep -v '#' | awk -F'=' '{print $2}')
volumeName=$(grep 'VOL_NAME=' $envFile | grep -v '#' | awk -F'=' '{print $2}')
networkMode=$(grep 'NETWORK_MODE=' $envFile | grep -v '#' | awk -F'=' '{print $2}')
transcoderDevice=$(grep 'DEVICES=' $envFile | grep -v '#' | awk -F'=' '{print $2}')
stackNumber=$(grep 'CDVR_CONTAINER=' $envFile | grep -v '#' | awk -F'=' '{print $2}')

if [[ -n $dockerVolume ]]; then
  sed -i 's/#volumes:/volumes:/' $stackFile
  sed -i 's/#channels-dvr:/'$dockerVolume':/' $stackFile
  [[ -n $volumeExternal ]] && sed -i 's/#external:/external:/' $stackFile
  [[ -n $volumeName ]] && sed -i 's/#name:/name:/' $stackFile
fi

if [[ -n $networkMode ]]; then
  sed -i 's/#network_mode:/network_mode:/' $stackFile
  sed -i 's/ports:/#ports:/' $stackFile
  sed -i 's/- \${HOST_PORT}:\${CHANNELS_PORT}/#- \${HOST_PORT}:\${CHANNELS_PORT}/' $stackFile
fi

if [[ -n $transcoderDevice ]]; then
  sed -i 's/#devices:/devices:/' $stackFile
  sed -i 's/#- \/dev\/dri:/- \/dev\/dri:/' $stackFile
fi

if [[ -n $stackNumber ]]; then
  sed -i "s/container_name: channels-dvr/container_name: channels-dvr$stackNumber/" $stackFile
  sed -i "s/- \${HOST_DIR}\/channels-dvr/- \${HOST_DIR}\/channels-dvr$stackNumber/" $stackFile
  stackName="$stackName$stackNumber"
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
