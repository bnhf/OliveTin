#!/bin/bash
set -e #-x

runInterval=$1
healthchecksIO=$2

cd /config
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
mkdir -p $DIR/data

while true; do
  rm -rf $DIR/basic.xml

  [[ $runInterval == "once" ]] && echo "Downloading latest iCal data..."
  python3 $DIR/ical_2_xmltv.py "https://calendar.google.com/calendar/ical/mg877fp19824mj30g497frm74o%40group.calendar.google.com/public/basic.ics" "TWiT.tv"

  mv $DIR/basic.xml $DIR/data/
  
  [[ $runInterval == "once" ]] && echo "done." \
  && exit 0

  [[ -n $healthchecksIO ]] \
  && curl -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] \
  && sleep $runInterval
done