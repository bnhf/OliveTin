#!/bin/bash
# kisterupdater.sh
# 2025.05.05

#set -x

dvr="$1"
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval="$2"
  [[ "$runInterval" == "0" ]] && runInterval=""
logFile=/config/"$channelsHost"-"$channelsPort"_kisterupdater_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
channelSource="$3"
m3uName="$4"
m3uFile=/config/data/"$channelsHost"-"$channelsPort"/"$m3uName"
m3uTmp=/tmp/"$channelsHost"-"$channelsPort"/"$m3uName"
mkdir -p /tmp/"$channelsHost"-"$channelsPort"

extractVID() {
  truncate -s 0 $m3uTmp
  while IFS= read -r m3uLine; do
    if [[ "$m3uLine" = https://kister.net/mpl/yt2m3u8?w=@* ]]; then
      kisterUrl=$(echo "$m3uLine" | grep -oP '(?<=[wv]=)[^&]+') \
        && echo "# yt-source=https://www.youtube.com/$kisterUrl/live" >> $m3uTmp
    elif [[ "$m3uLine" = https://kister.net/mpl/yt2m3u8?w=* ]]; then
      kisterUrl=$(echo "$m3uLine" | grep -oP '(?<=[wv]=)[^&]+') \
        && echo "# yt-source=https://www.youtube.com/watch?v=$kisterUrl" >> $m3uTmp
    elif [[ "$m3uLine" = https://www.youtube.com/* ]]; then
      kisterUrl=$(echo "$m3uLine") \
        && echo "# yt-source=$kisterUrl" >> $m3uTmp
    else
      echo "$m3uLine" >> $m3uTmp
      kisterUrl=""
    fi
  done < "$m3uFile"
  cp $m3uTmp $m3uFile
}

m3uUpdates() {
  while true; do
    timeout 2 curl --head www.youtube.com > /dev/null 2>&1 || { echo "$(date -Iseconds) www.youtube.com connection failed, retrying in 60 seconds"; sleep 60; continue; }
    truncate -s 0 $m3uTmp
    while IFS= read -r m3uLine; do
      if [[ "$m3uLine" =~ ^#\ yt-source=(.+)$ ]]; then
        liveUrl="${BASH_REMATCH[1]}"
        manifestUrl=$(curl -s $liveUrl | grep -oP '"hlsManifestUrl":\s*"\K[^"]+')
        [[ -n $manifestUrl ]] && echo -e "$m3uLine\n$manifestUrl" >> $m3uTmp || echo "$m3uLine" >> $m3uTmp
      elif [[ "$m3uLine" =~ ^https* ]]; then
        echo
      else
        echo "$m3uLine" >> $m3uTmp
        liveUrl=""
      fi
    done < "$m3uFile"
    cp $m3uTmp $m3uFile
    echo -e "\nRefreshing $channelSource with the latest Manifest URL values..."
    curl -s -XPOST http://"$dvr"/providers/m3u/sources/"$channelSource"/refresh
    sleep $runInterval
  done
}

main() {
  extractVID
  [ -f $m3uFile ] && m3uUpdates || echo "$m3uFile doesn't exist"
}

main
