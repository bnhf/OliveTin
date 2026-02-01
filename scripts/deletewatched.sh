#!/bin/bash
# deletewatched.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

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
  watchedVideos=$(curl -s http://$dvr/api/v1/videos?watched=true | tee -a "$logFile" | jq -r '.[].id')
  watchedVideos=($watchedVideos)
  echo -e "\n\nDeleting watched videos..." >> "$logFile"

  for watchedVideo in "${watchedVideos[@]}"; do
    echo "Deleting watched video with File ID $watchedVideo" >> "$logFile"
    curl -s -X DELETE http://$dvr/dvr/files/$watchedVideo >> "$logFile"
    echo >> "$logFile"
  done

  [[ $runInterval == "once" ]] && echo -e "done.\n" >> "$logFile" \
    && touch $runFile \
    && exit 0

  [[ -n $healthchecksIO ]] \
    && curl -s -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] \
    && touch $runFile \
    && sleep $runInterval  
done
