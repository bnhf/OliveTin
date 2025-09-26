#!/bin/bash
# portainerstack.sh
# 2025.09.15

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

stackName="$1"
portainerHost="${2:-$PORTAINER_HOST}"
portainerToken="${3:-$PORTAINER_TOKEN}"
[[ -n $PORTAINER_PORT ]] && portainerPort="${4:-$PORTAINER_PORT}" || portainerPort="9443"
yamlCopied="$5"
portainerName=${PORTAINER_NAME:-local}
portainerEnv=$(curl -s -k -H "X-API-Key: $portainerToken" "http://$portainerHost:9000/api/endpoints" | jq --arg portainerName "$portainerName" '.[] | select(.Name==$portainerName) | .Id') \
  && [[ -z $portainerEnv ]] && portainerEnv=$(curl -s -k -H "X-API-Key: $portainerToken" "https://$portainerHost:$portainerPort/api/endpoints" | jq --arg portainerName "$portainerName" '.[] | select(.Name==$portainerName) | .Id')
curl -s -o /dev/null http://$portainerHost:9000 \
  && portainerURL="http://$portainerHost:9000/api/stacks/create/standalone/string?endpointId=$portainerEnv" \
  || portainerURL="https://$portainerHost:$portainerPort/api/stacks/create/standalone/string?endpointId=$portainerEnv"
[[ "$yamlCopied" != "true" ]] && cp /config/$stackName.yaml /tmp
stackFile="/tmp/$stackName.yaml"
envFile="/tmp/$stackName.env"
dirsFile="/tmp/$stackName.dirs"

dockerVolume=$(grep 'DVR_SHARE=' $envFile | grep -v '/' | awk -F'=' '{print $2}')
volumeExternal=$(grep 'VOL_EXTERNAL=' $envFile | grep -v '#' | awk -F'=' '{print $2}')
volumeName=$(grep 'VOL_NAME=' $envFile | grep -v '#' | awk -F'=' '{print $2}')
networkMode=$(grep 'NETWORK_MODE=' $envFile | grep -v '#' | awk -F'=' '{print $2}')
transcoderDevice=$(grep 'DEVICES=' $envFile | grep -v '#' | awk -F'=' '{print $2}')
stackNumber=$(grep '_CONTAINER=' $envFile | grep -v '#' | awk -F'=' '{print $2}')

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
  sed -i "s/container_name: $stackName/container_name: $stackName$stackNumber/" $stackFile
  sed -i "s/- \${HOST_DIR}\/$stackName/- \${HOST_DIR}\/$stackName$stackNumber/" $stackFile
  stackName="$stackName$stackNumber"
fi

stackContent=$(sed 's/\\/\\\\/g' "$stackFile" | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

synologyDirs() {
while IFS= read -r hostDir; do
    if [[ "$hostDir" == /volume1/docker/* ]]; then
      subDir="${hostDir#/volume1/docker/}"
      docker run --rm -v /volume1/docker:/data alpine mkdir -p /data/$subDir
    fi
done < "$dirsFile"
}

#[[ "$(docker info --format '{{.DockerRootDir}}')" == "/volume1/@docker" ]] && synologyDirs

stackEnvVars="["

while IFS= read -r line; do
  key="${line%%=*}"
  value="${line#*=}"
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
portainerResponse=$(curl -s -k -X POST -H "Content-Type: application/json" -H "X-API-Key: ${portainerToken}" -d "$stackJSON" "$portainerURL")

[[ -z $portainerResponse ]] && exit 1

echo $portainerResponse
echo "$portainerResponse" | jq -e '.Id != null' && exit 0 || exit 1
