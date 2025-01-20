#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_backupdatabase_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
runFile=/tmp/"$channelsHost"-"$channelsPort"_backupdatabase.run

while true; do
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") - Checking if CDVR Server is busy..." >> $logFile
  dvrBusy=$(curl http://$dvr/dvr | jq -r '.busy')
  echo "$dvrBusy" >> $logFile
  
  [[ $dvrBusy == "true" ]] && [[ $runInterval == "once" ]] && echo -e "CDVR Server is busy, try again later." >> $logFile
  [[ $dvrBusy == "true" ]] && [[ $runInterval != "once" ]] && echo -e "CDVR Server is busy, next check in $runInterval" >> $logFile

  [[ $dvrBusy == "false" ]] && echo -e "$(date +"%Y-%m-%d %H:%M:%S") - Backing up CDVR database..." >> $logFile
  [[ $dvrBusy == "false" ]] && curl -XPOST http://$dvr/backups >> $logFile


  [[ $runInterval == "once" ]] && echo -e "\ndone.\n" >> "$logFile" \
    && touch $runFile \
    && exit 0

  [[ -n $healthchecksIO ]] \
    && curl -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] && echo -e "\n$(date +"%Y-%m-%d %H:%M:%S") - Backup complete, with continuing backups set for $runInterval intervals.\n" >> "$logFile" \
    && touch $runFile \
    && sleep $runInterval  
done
