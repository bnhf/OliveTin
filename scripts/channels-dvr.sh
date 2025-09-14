#!/bin/bash
# channels-dvr.sh
# 2025.09.12

set -x

extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
hostPort="$2"
channelsPort="$3"
dvrShare="$6"
dvrContainerDir="$7"
cdvrContainer="${12}" && [[ "$cdvrContainer" == "#" ]] && cdvrContainer=""
[[ -z $PORTAINER_HOST ]] && portainerHost="${CHANNELS_DVR%%:*}"
[[ -f /config/olivetin.token ]] && portainerToken=$(cat /config/olivetin.token)
dirsFile="/tmp/$extension.dirs"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
"CHANNELS_PORT=$3"
"TZ=$4"
"HOST_DIR=$5"
"DVR_SHARE=$6"
"DVR_CONTAINER_DIR=$7"
"VOL_EXTERNAL=$8"
"VOL_NAME=$9"
"NETWORK_MODE=${10}"
"DEVICES=${11}"
"CDVR_CONTAINER=${12}"
)

synologyDirs=(
"$5/channels-dvr$cdvrContainer"
)

printf "%s\n" "${envVars[@]}" > $envFile
printf "%s\n" "${synologyDirs[@]}" > $dirsFile

sed -i '/=#/d' $envFile

stackCreated() {
  echo "A new stack, named channels-dvr$cdvrContainer has been created in Portainer at http://$PORTAINER_HOST:9000 or https://$PORTAINER_HOST:9443"
  echo "You can now access your new Channels DVR container at http://$PORTAINER_HOST:$hostPort (if bridge network), or http://$PORTAINER_HOST:$channelsPort (if host network)."
  echo "Setup Channels DVR to use this container directory $dvrContainerDir (case sensitive) for storing recordings, since that is mapped to the host directory $dvrShare you specified."
}

/config/portainerstack.sh $extension "$portainerHost" "$portainerToken"

[[ $? == 1 ]] && exit 1 || { stackCreated; exit 0; }
