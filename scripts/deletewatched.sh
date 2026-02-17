#!/bin/bash
# deletewatched.sh
# 2026.02.11

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_deletewatched_latest.log
logTemp=/tmp/"$channelsHost"-"$channelsPort"_deletewatched_latest.log
  [[ -f $logTemp ]] && rm $logTemp
logForeground=/tmp/"$channelsHost"-"$channelsPort"_deletewatched_foreground.log
runFile=/tmp/"$channelsHost"-"$channelsPort"_deletewatched.run
firstRun=true

while true; do
  echo -e "\nRetrieving watched video IDs for $dvr..." >> "$logTemp"
  watchedVideos=$(curl -s http://$dvr/api/v1/videos?watched=true | tee -a "$logTemp" | jq -r '.[].id')
  watchedVideos=($watchedVideos)
  echo -e "\n\nDeleting watched videos..." >> "$logTemp"

  for watchedVideo in "${watchedVideos[@]}"; do
    echo "Deleting watched video with File ID $watchedVideo" >> "$logTemp"
    curl -s -X DELETE http://$dvr/dvr/files/$watchedVideo >> "$logTemp"
    echo >> "$logTemp"
  done

  [[ "$firstRun" == "true" ]] \
    && { cat "$logTemp" >> "$logForeground"; firstRun=false; } \
    || sed 's/\x1b\[[0-9;]*m//g' "$logTemp" >> "$logFile"

  [[ -n $healthchecksIO ]] \
    && curl -s -m 10 --retry 5 $healthchecksIO

  touch $runFile

  [[ $runInterval == "once" ]] \
    && exit 0

  [[ $runInterval != "once" ]] \
    && rm $logTemp \
    && sleep $runInterval
done
