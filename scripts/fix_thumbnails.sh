#!/bin/bash
# fix_thumbnails.sh
# 2026.02.11

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_fix_thumbnails_latest.log
logTemp=/tmp/"$channelsHost"-"$channelsPort"_fix_thumbnails_latest.log
  [[ -f $logTemp ]] && rm $logTemp
logForeground=/tmp/"$channelsHost"-"$channelsPort"_fix_thumbnails_foreground.log
runFile=/tmp/"$channelsHost"-"$channelsPort"_fix_thumbnails.run
firstRun=true

while true; do
  [[ $runInterval == "once" ]] && echo "Retrieving YouTube video_groups for $dvr..." >> "$logTemp"
  videoGroups=$(curl -s http://$dvr/api/v1/video_groups)
  videoGroups=$(echo "$videoGroups" | jq -r '.[] | .id' | tr '\n' ' ')
  ids=($videoGroups)

  for id in "${ids[@]}"; do
    echo "Fixing thumbnails for video_group $id" >> "$logTemp"
    ruby /config/fix_thumbnails.rb "$id"
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
