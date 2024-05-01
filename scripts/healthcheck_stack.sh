#! /bin/bash

olivetinStackName="\"$1\""
windowsHost="$2"
hostCommand="$3"
portainerToken="$PORTAINER_TOKEN"
  [[ -z $portainerToken ]] && echo "No Portainer token present. Generate in Portainer WebUI and add it to OliveTin env vars" && exit 0
olivetinStackID=$(curl -k -s -H "X-API-Key: ${portainerToken}" https://$windowsHost:9443/api/stacks | jq '.[] | select(.Name=='$olivetinStackName') | .Id')

case $hostCommand in
  envvars)
    curl -k -s -H "X-API-Key: ${portainerToken}" https://$windowsHost:9443/api/stacks | jq -r '.[] | select(.Name=='$olivetinStackName') | .Env[] | "\(.name)=\(.value)"'
    ;;
  compose)
    curl -k -s -H "X-API-Key: ${portainerToken}" https://$windowsHost:9443/api/stacks/$olivetinStackID/file | jq -r '.StackFileContent'
    ;;
  *)
    echo "Command not recognized"
    ;;
esac