#!/bin/bash
# portainer.sh
# 2025.09.21

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

[[ -z $PORTAINER_HOST ]] && portainerHost="${CHANNELS_DVR%%:*}" || portainerHost="$PORTAINER_HOST"
portainerAdminPassword="$1"
  [[ ${#portainerAdminPassword} -lt 12 ]] && echo "Password too short -- 12 character minimum." && exit 0
hashedPassword=$(htpasswd -nbB admin "$portainerAdminPassword" | cut -d ":" -f 2)
portainerHttpPort="$2"
portainerHttpsPort="$3"

docker run -d \
  -p $portainerHttpPort:9000 \
  -p $portainerHttpsPort:9443 \
  --name portainer \
  --restart always \
  --pull always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest \
  --admin-password "$hashedPassword" \
&& echo "Portainer container created successfully" \
|| { echo "Portainer container creation failed"; exit 0; }

sleep 2

jsonWebToken=$(
curl -s -X POST "http://$portainerHost:$portainerHttpPort/api/auth" \
        -H "Content-Type: application/json" \
        -d '{"Username":"admin", "Password":"'$portainerAdminPassword'"}' \
        | jq -r '.jwt'
)

portainerToken=$(
curl -s -X POST "http://$portainerHost:$portainerHttpPort/api/users/1/tokens" \
        -H "Authorization: Bearer $jsonWebToken" \
        -H "Content-Type: application/json" \
        -d '{"password": "'$portainerAdminPassword'", "description": "olivetin"}' \
        | jq -r '.rawAPIKey'
)

portainerEnv=$(
curl -s -X POST "http://$portainerHost:$portainerHttpPort/api/endpoints" \
        -H "Authorization: Bearer $jsonWebToken" \
        -F "Name=local" \
        -F "EndpointCreationType=1" \
        | jq -r '.Id'
)

[[ -n $portainerToken ]] && {
  echo -e "\nA Portainer token named olivetin has been created...";
  echo "$portainerToken" > /config/olivetin.token;
  echo "$portainerToken";
  echo;
  echo "and a Portainer local environment initialized...";
  echo "$portainerEnv" > /config/portainer_env.id;
  echo "$portainerEnv";
} || echo -e "\nPortainer token creation and environment initialization failed..."
