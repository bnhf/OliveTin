#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_updateprerelease_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
runFile=/tmp/"$channelsHost"-"$channelsPort"_updateprerelease.run

while true; do
  dvrBusy=$(curl http://$dvr/dvr | jq -r '.busy')
  echo -e "Checking if CDVR Server is running the latest pre-release..."
  [[ $dvrBusy == "false" ]] && curl -XPUT http://$dvr/updater/check/prerelease >> $logFile


  [[ $runInterval == "once" ]] && echo -e "\ndone.\n" >> "$logFile" \
    && touch $runFile \
    && exit 0

  [[ -n $healthchecksIO ]] \
    && curl -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] && echo -e "\nInitial check complete, with continuing checks set for $runInterval intervals.\n" >> "$logFile" \
    && touch $runFile \
    && sleep $runInterval  
done
