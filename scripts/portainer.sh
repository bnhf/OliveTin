#!/bin/bash
# portainer.sh
# 2025.03.20

set -x

portainerAdminPassword="$1"
hashedPassword=$(htpasswd -nbB admin "$portainerAdminPassword" | cut -d ":" -f 2)
#hashedPassword=$(printf "%s\n" "$portainerAdminPassword" | htpasswd -nbB admin - | cut -d ":" -f 2)
#escapedHashedPassword=$(echo "$hashedPassword" | sed 's/\$/$$/g')

docker run -d \
  -p 8000:8000 \
  -p 9000:9000 \
  -p 9443:9443 \
  --name portainer \
  --restart always \
  --pull always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest \
--admin-password "$hashedPassword"
