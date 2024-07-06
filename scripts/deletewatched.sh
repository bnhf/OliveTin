#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_deletewatched_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
runFile=/tmp/"$channelsHost"-"$channelsPort"_deletewatched.run

while true; do
  echo -e "\nRetrieving watched video IDs for $dvr..." >> "$logFile"
  watchedVideos=$(curl http://$dvr/api/v1/videos?watched=true | tee -a "$logFile" | jq -r '.[].id')
  watchedVideos=($watchedVideos)
  echo -e "\n\nDeleting watched videos..." >> "$logFile"

  for watchedVideo in "${watchedVideos[@]}"; do
    echo "Deleting watched video with File ID $watchedVideo" >> "$logFile"
    curl -X DELETE http://$dvr/dvr/files/$watchedVideo >> "$logFile"
    echo >> "$logFile"
  done

  [[ $runInterval == "once" ]] && echo -e "done.\n" >> "$logFile" \
    && touch $runFile \
    && exit 0

  [[ -n $healthchecksIO ]] \
    && curl -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] \
    && touch $runFile \
    && sleep $runInterval  
done
