#!/bin/bash
set -e -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_ical_2_xmltv_latest.log
runFile=/tmp/"$channelsHost"-"$channelsPort"_ical_2_xmltv.run

cd /config
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
mkdir -p $DIR/"$channelsHost"-"$channelsPort"_data

while true; do
  rm -rf $DIR/basic.xml

  echo "Downloading latest iCal data for $dvr..." >> $logFile
  python3 $DIR/ical_2_xmltv.py "https://calendar.google.com/calendar/ical/mg877fp19824mj30g497frm74o%40group.calendar.google.com/public/basic.ics" "TWiT.tv"

  mv $DIR/basic.xml $DIR/"$channelsHost"-"$channelsPort"_data/
  
  [[ $runInterval == "once" ]] && echo "done." >> $logFile \
    && touch $runFile \
    && exit 0

  [[ -n $healthchecksIO ]] \
    && curl -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] \
    && touch $runFile \
    && sleep $runInterval
done