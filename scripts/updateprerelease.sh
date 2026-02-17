#!/bin/bash
# updateprerelease.sh
# 2026.02.11

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_updateprerelease_latest.log
logTemp=/tmp/"$channelsHost"-"$channelsPort"_updateprerelease_latest.log
  [[ -f $logTemp ]] && rm $logTemp
logForeground=/tmp/"$channelsHost"-"$channelsPort"_updateprerelease_foreground.log
runFile=/tmp/"$channelsHost"-"$channelsPort"_updateprerelease.run
firstRun=true

while true; do
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") - Checking if CDVR Server is busy..." >> $logTemp
  dvrBusy=$(curl -s http://$dvr/dvr | jq -r '.busy')
  echo "$dvrBusy" >> $logTemp

  [[ $dvrBusy == "true" ]] && [[ $runInterval == "once" ]] && echo -e "CDVR Server is busy, try again later." >> $logTemp
  [[ $dvrBusy == "true" ]] && [[ $runInterval != "once" ]] && echo -e "CDVR Server is busy, next check in $runInterval" >> $logTemp

  [[ $dvrBusy == "false" ]] && echo -e "$(date +"%Y-%m-%d %H:%M:%S") - Checking if CDVR Server is running the latest pre-release..." >> $logTemp
  [[ $dvrBusy == "false" ]] && curl -s -XPUT http://$dvr/updater/check/prerelease >> $logTemp

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
