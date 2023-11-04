#!/bin/bash

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_pingcdvr_latest.log

while true; do

  if ping -q -c 1 -W 2 $channelsHost | sed '/^$/d' | sed 's/PING/\nPING/' >> $logFile; then
    [[ $runInterval == "once" ]] \
    && exit 0

    [[ -n $healthchecksIO ]] \
    && curl -m 10 --retry 5 $healthchecksIO
  fi

  [[ $runInterval != "once" ]] \
  && sleep $runInterval
done