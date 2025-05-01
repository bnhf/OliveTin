#!/bin/bash
# portainertoken.sh
# 2025.03.25

set -x

portainerHost="$1"
portainerAdminPassword="$2"
portainerTokenName="$3"
portainerPort="$PORTAINER_PORT"
curl -s -o /dev/null http://$portainerHost:9000 \
  && portainerURL="http://$portainerHost:9000/api" \
  || portainerURL="https://$portainerHost:$portainerPort/api"

jsonWebToken=$(
curl -s -X POST "$portainerURL/auth" \
        -H "Content-Type: application/json" \
        -d '{"Username":"admin", "Password":"'$portainerAdminPassword'"}' \
        | jq -r '.jwt'
)

portainerToken=$(
curl -s -X POST "$portainerURL/users/1/tokens" \
        -H "Authorization: Bearer $jsonWebToken" \
        -H "Content-Type: application/json" \
        -d '{"password": "'$portainerAdminPassword'", "description": "'$portainerTokenName'"}' \
        | jq -r '.rawAPIKey'
)

echo "A Portainer token named olivetin has been created..."
echo "Store it in a safe place. You will not be able to view it again:"
echo "$portainerToken"
