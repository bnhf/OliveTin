#!/bin/bash
# deletelogs.sh
# 2026.02.11

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
recordingLogAge=$(echo "$runInterval" |  sed 's/d//')
[[ $runInterval == "once" ]] && recordingLogAge=30
logFile=/config/"$channelsHost"-"$channelsPort"_deletelogs_latest.log
logTemp=/tmp/"$channelsHost"-"$channelsPort"_deletelogs_latest.log
  [[ -f $logTemp ]] && rm $logTemp
logForeground=/tmp/"$channelsHost"-"$channelsPort"_deletelogs_foreground.log
runFile=/tmp/"$channelsHost"-"$channelsPort"_deletelogs.run
firstRun=true

dvrDir="$channelsHost-$channelsPort"
#[ -z $CHANNELS_DVR_ALTERNATES ] && dvrDir="dvr"

while true; do
  [ -d "/mnt/$dvrDir/Logs/recording" ] \
    && echo "Deleting recording log files for $dvr that are more than $recordingLogAge days old" >> $logTemp \
    && find /mnt/$dvrDir/Logs/recording/* -type d -mtime +$recordingLogAge -exec rm -r {} \; >> $logTemp  2>&1

  sed -i 's/No such file or directory/Deleted/g' $logTemp

  if [ ! -d "/mnt/$dvrDir/Logs/recording" ]; then
    echo "Your Channels DVR Server's /dvr directory needs to be bound to this container" >> $logTemp
    cat $logTemp >> $logFile
    exit 0
  fi

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
