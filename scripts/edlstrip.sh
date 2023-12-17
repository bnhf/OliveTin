#/bin/bash

set -x

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
