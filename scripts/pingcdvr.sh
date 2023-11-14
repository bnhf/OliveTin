#!/bin/bash

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_pingcdvr_latest.log

while true; do
  pingDVR=$(ping -q -c 1 -W 2 $channelsHost)

  [[ $? -eq 0 && -n $healthchecksIO ]] \
    && curl -m 10 --retry 5 $healthchecksIO

  { printf "\n%s" "$(date)"; echo "$pingDVR" | sed '/^$/d' | sed 's/PING/\nPING/'; } >> $logFile

  [[ $runInterval == "once" ]] \
    && exit 0 \
    || sleep $runInterval
done