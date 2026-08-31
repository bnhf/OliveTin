#!/bin/bash
# channels-dvr.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

hostPort="$2"
channelsPort="$3"
hostDir="$5"
dvrShare="$6"
dvrContainerDir="$7"
cdvrContainer=$(emptyIfHash "${12}")

# bootstrap Action -- PORTAINER_HOST may not be set yet; fall back to the
# CHANNELS_DVR host and a token file, and hand both to portainerstack.sh
portainerHost="${PORTAINER_HOST:-${CHANNELS_DVR%%:*}}"
[[ -f /config/olivetin.token ]] && portainerToken=$(cat /config/olivetin.token)

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
"$hostDir/channels-dvr$cdvrContainer"
)

stackCreated() {
  echo "A new stack, named channels-dvr$cdvrContainer has been created in Portainer at http://$portainerHost:9000 or https://$portainerHost:9443"
  echo "You can now access your new Channels DVR container at http://$portainerHost:$hostPort (if bridge network), or http://$portainerHost:$channelsPort (if host network)."
  echo "Setup Channels DVR to use this container directory $dvrContainerDir (case sensitive) for storing recordings, since that is mapped to the host directory $dvrShare you specified."
}

# one-clickCreateStack [extra portainerstack.sh args] -- uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack "$portainerHost" "$portainerToken"
stackCreated
