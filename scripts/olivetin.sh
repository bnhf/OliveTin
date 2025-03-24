#!/bin/bash
# olivetin.sh
# 2025.03.23

set -x

echo "TAG=$1"

searchDomain=$(grep '^search' /etc/resolv.conf | awk '{$1=""; print $0}' | sed 's/^ *//') 
  echo "DOMAIN=${2:-$searchDomain}"

echo "HOST_PORT=$3"
echo "CHANNELS_DVR_HOST=$4"
echo "CHANNELS_DVR_PORT=$5"

IFS=' ' read -r -a channelsDVRs <<< "$6"

for channelsDVR in "${!channelsDVRs[@]}"; do
    dvrNumber=$((channelsDVR + 2))
    channelsDVRx="${channelsDVRs[channelsDVR]}"

    channelsDVRHost="${channelsDVRx%%:*}"
    channelsDVRPort="${channelsDVRx##*:}"

    eval "channelsDVR$dvrNumber='$channelsDVRx'"
    eval "channelsDVR${dvrNumber}Host='$channelsDVRHost'"
    eval "channelsDVR${dvrNumber}Port='$channelsDVRPort'"

    echo "CHANNELS_DVR${dvrNumber}_HOST=$channelsDVRHost"
    echo "CHANNELS_DVR${dvrNumber}_PORT=$channelsDVRPort"
done

echo "CHANNELS_CLIENTS=$7"
echo "ALERT_EMAIL_SERVER=$8"
echo "ALERT_EMAIL_FROM=$9"
echo "ALERT_EMAIL_PASS=${10}"
echo "ALERT_EMAIL_TO=${11}"
echo "UPDATE_YAMLS=${12}"
echo "UPDATE_SCRIPTS=${13}"

localTimezone=$(cat /etc/timezone)
echo "TZ=${14:-$localTimezone}"

echo "HOST_DIR=${15}"

olivetinDockerJSON=$(docker inspect --format '{{ json .Mounts }}' olivetin | jq)

volumeCheck() {
  local variableName="$1"
  local dockerInspect="$2"

  if [[ "$dockerInspect" =~ /var/lib/docker/volumes/([^/]+)/_data ]]; then
    local extracted="${BASH_REMATCH[1]}"
    [[ "$extracted" == "olivetin" ]] && extracted=""
    printf -v "$variableName" "%s" "$extracted"
  fi
}

dvrShare=$(curl -s http://$4:$5/dvr | jq -r '.path')
dvrShareInspect=$(echo $olivetinDockerJSON | jq -r '.[] | select(.Destination == "/mnt/'"$4"'-'"$5"'") | .Source')
  [[ $dvrShare == *\\* ]] && windowsOS=true || windowsOS=""
  [[ $windowsOS ]] && dvrShare=$(echo "$dvrShare" | sed 's|\\|/|g')
  [[ -z "${16}" && -n "$dvrShareInspect" ]] && dvrShare="$dvrShareInspect"
  echo "DVR_SHARE=${16:-$dvrShare}"

logsShare=$(curl -s http://$4:$5/log?n=100000 | grep -m 1 "Starting Channels DVR" | awk '{print $NF}' | awk '{sub(/[\\/]?data$/, ""); print}')
logsShareInspect=$(echo $olivetinDockerJSON | jq -r '.[] | select(.Destination == "/mnt/'"$4"'-'"$5"'_logs") | .Source')
  [[ $logsShare == *\\* ]] && windowsOS=true || windowsOS=""
  [[ $windowsOS ]] && logsShare=$(echo "$logsShare" | sed 's|\\|/|g')
  [[ -z "${17}" && -n "$logsShareInspect" ]] && logsShare="$logsShareInspect"
  echo "LOGS_SHARE=${17:-$logsShare}"

tubearchivistShareInspect=$(echo $olivetinDockerJSON | jq -r '.[] | select(.Destination == "/mnt/'"$4"'-'"$5"'_ta") | .Source')
  [[ -z "${18}" && -n "$tubearchivistShareInspect" ]] &&  tubearchivistShare="$tubearchivistShareInspect" || tubearchivistShare="$dvrShare"
  echo "TUBEARCHIVIST_SHARE=${18:-$tubearchivistShare}"

dvr2ShareInspect=$(echo $olivetinDockerJSON | jq -r '.[] | select(.Destination == "/mnt/'"$channelsDVR2Host"'-'"$channelsDVR2Port"'") | .Source')
  volumeCheck dvr2ShareInspect "$dvr2ShareInspect"
echo "DVR2_SHARE=${19:-$dvr2ShareInspect}"

logs2ShareInspect=$(echo $olivetinDockerJSON | jq -r '.[] | select(.Destination == "/mnt/'"$channelsDVR2Host"'-'"$channelsDVR2Port"'_logs") | .Source')
  volumeCheck logs2ShareInspect "$logs2ShareInspect"
echo "LOGS2_SHARE=${20:-$logs2ShareInspect}"

tubearchivist2ShareInspect=$(echo $olivetinDockerJSON | jq -r '.[] | select(.Destination == "/mnt/'"$channelsDVR2Host"'-'"$channelsDVR2Port"'_ta") | .Source')
  volumeCheck tubearchivist2ShareInspect "$tubearchivist2ShareInspect"
echo "TUBEARCHIVIST2_SHARE=${21:-$tubearchivist2ShareInspect}"

dvr3ShareInspect=$(echo $olivetinDockerJSON | jq -r '.[] | select(.Destination == "/mnt/'"$channelsDVR3Host"'-'"$channelsDVR3Port"'") | .Source')
  volumeCheck dvr3ShareInspect "$dvr3ShareInspect"
echo "DVR3_SHARE=${22:-$dvr3ShareInspect}"

logs3ShareInspect=$(echo $olivetinDockerJSON | jq -r '.[] | select(.Destination == "/mnt/'"$channelsDVR3Host"'-'"$channelsDVR3Port"'_logs") | .Source')
  volumeCheck logs3ShareInspect "$logs3ShareInspect"
echo "LOGS3_SHARE=${23:-$logs3ShareInspect}"

tubearchivist3ShareInspect=$(echo $olivetinDockerJSON | jq -r '.[] | select(.Destination == "/mnt/'"$channelsDVR3Host"'-'"$channelsDVR3Port"'_ta") | .Source')
  volumeCheck tubearchivist3ShareInspect "$tubearchivist3ShareInspect"
echo "TUBEARCHIVIST3_SHARE=${24:-$tubearchivist3ShareInspect}"

echo "HOST_SFS_PORT=${25}"
echo "FOLDER=${26}"
echo "PORTAINER_TOKEN=${27}"
echo "PORTAINER_HOST=${28}"
echo "PORTAINER_PORT=${29}"
echo "PORTAINER_ENV=${30}"
echo "PERSISTENT_LOGS=${31}"
