#!/bin/bash

runInterval=$1
healthchecksIO=$2

while true; do
  [[ $runInterval == "once" ]] && echo "Retrieving YouTube video_groups..."
  videoGroups=$(curl http://$CHANNELS_DVR/api/v1/video_groups)

  ids=$(echo "$videoGroups" | jq -r '.[] | .id')
  
  for id in $ids; do
    echo "Fixing thumbnails for video_group $id"
    ruby /config/fix_thumbnails.rb "$id"
  done

  [[ $runInterval == "once" ]] && echo "done." \
  && exit 0

  [[ -n $healthchecksIO ]] \
  && curl -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] \
  && sleep $runInterval  
done