#!/bin/bash
# edlstrip.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
sourcePath="$2"
sourceFile="$3"
outputPath="$4"
outputFile="$5"
logFile=/config/"$channelsHost"-"$channelsPort"_edlstrip_latest.log

dvrDir="$channelsHost-$channelsPort"
[ -z $CHANNELS_DVR_ALTERNATES ] && dvrDir="dvr"

nohup python3 -u /usr/local/bin/edlstrip /mnt/"$dvrDir"/"$sourcePath"/"$sourceFile".mpg --outfile /mnt/"$dvrDir"/"$sourcePath"/"$outputFile".mkv > $logFile 2>&1 &

sleep 5
cat $logFile
echo "----------------------------------------"
echo "It will take several minutes for $outputFile.mkv to appear in /mnt/$dvrDir/$sourcePath"
echo "You can check $logFile if you want to monitor progress"
