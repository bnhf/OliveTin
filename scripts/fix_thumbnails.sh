#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_fix_thumbnails_latest.log
runFile=/tmp/"$channelsHost"-"$channelsPort"_fix_thumbnails.run

while true; do
  [[ $runInterval == "once" ]] && echo "Retrieving YouTube video_groups for $dvr..." >> "$logFile"
  videoGroups=$(curl http://$dvr/api/v1/video_groups)
  videoGroups=$(echo "$videoGroups" | jq -r '.[] | .id' | tr '\n' ' ')  
  ids=($videoGroups)
  
  for id in "${ids[@]}"; do
    echo "Fixing thumbnails for video_group $id" >> "$logFile"
    ruby /config/fix_thumbnails.rb "$id"
  done

  [[ $runInterval == "once" ]] && echo "done." >> "$logFile" \
    && touch $runFile \
    && exit 0

  [[ -n $healthchecksIO ]] \
    && curl -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] \
    && touch $runFile \
    && sleep $runInterval  
done