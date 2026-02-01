#!/bin/bash
# updateprerelease.sh
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
logFile=/config/"$channelsHost"-"$channelsPort"_updateprerelease_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
runFile=/tmp/"$channelsHost"-"$channelsPort"_updateprerelease.run

while true; do
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") - Checking if CDVR Server is busy..." >> $logFile
  dvrBusy=$(curl -s http://$dvr/dvr | jq -r '.busy')
  echo "$dvrBusy" >> $logFile
  
  [[ $dvrBusy == "true" ]] && [[ $runInterval == "once" ]] && echo -e "CDVR Server is busy, try again later." >> $logFile
  [[ $dvrBusy == "true" ]] && [[ $runInterval != "once" ]] && echo -e "CDVR Server is busy, next check in $runInterval" >> $logFile

  [[ $dvrBusy == "false" ]] && echo -e "$(date +"%Y-%m-%d %H:%M:%S") - Checking if CDVR Server is running the latest pre-release..." >> $logFile
  [[ $dvrBusy == "false" ]] && curl -s -XPUT http://$dvr/updater/check/prerelease >> $logFile


  [[ $runInterval == "once" ]] && echo -e "\ndone.\n" >> "$logFile" \
    && touch $runFile \
    && exit 0

  [[ -n $healthchecksIO ]] \
    && curl -s -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] && echo -e "\n$(date +"%Y-%m-%d %H:%M:%S") - Check complete, with continuing checks set for $runInterval intervals.\n" >> "$logFile" \
    && touch $runFile \
    && sleep $runInterval  
done
