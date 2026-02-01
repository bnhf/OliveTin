#!/bin/bash
# deletelogs.sh
# 2026.01.26

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
recordingLogAge=$(echo "$runInterval" |  sed 's/d//')
[[ $runInterval == "once" ]] && recordingLogAge=30
scriptBaseName=$(basename "$0" | sed 's/.sh//')
logFile=/config/"$channelsHost"-"$channelsPort"_deletelogs_latest.log
logTemp=/tmp/"$channelsHost"-"$channelsPort"_deletelogs_latest.log
runFile=/tmp/"$channelsHost"-"$channelsPort"_deletelogs.run

dvrDir="$channelsHost-$channelsPort"
#[ -z $CHANNELS_DVR_ALTERNATES ] && dvrDir="dvr"

while true; do
  [ -d "/mnt/$dvrDir/Logs/recording" ] \
    && echo "Deleting recording log files for $dvr that are more than $recordingLogAge days old" >> $logFile \
    && find /mnt/$dvrDir/Logs/recording/* -type d -mtime +$recordingLogAge -exec rm -r {} \; >> $logFile  2>&1
  cp $logFile /tmp \
  && sed -i 's/No such file or directory/Deleted/g' $logTemp \
  && cp $logTemp /config

  if [ ! -d "/mnt/$dvrDir/Logs/recording" ]; then
    echo "Your Channels DVR Server's /dvr directory needs to be bound to this container" >> $logFile
    exit 0
  fi

  [[ $runInterval == "once" ]] \
    && touch $runFile \
    && exit 0

  [[ -n $healthchecksIO ]] \
    && curl -s -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] \
    && touch $runFile \
    && sleep $runInterval
done
