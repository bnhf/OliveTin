#!/bin/bash
# stalexmlalerter.sh
# 2025.05.05

#set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
xmlURL=$3
staleness="$4"
  if [[ $staleness =~ ^([0-9]+)([hm])$ ]]; then
    num="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
    case "$unit" in
        h) staleSeconds=$((num * 3600)) ;;
        m) staleSeconds=$((num * 60)) ;;
    esac
  fi
appriseURL="$5"
logFile=/config/"$channelsHost"-"$channelsPort"_stalexml_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
runFile=/tmp/"$channelsHost"-"$channelsPort"_stalexml.run
while true; do
  staleXML=$(curl -s "$xmlURL" \
  | grep -oP '<tv[^>]*generated-ts="\K[^"]+')

  echo "$staleXML" | awk -v now="$(date +%s)" '{ if ((now - '$staleXML') > '$staleSeconds') exit 1 }'

  [[ $? -eq 1 ]] \
    && apprise -t "Samsung-TVPlus Stale XML Alert for $dvr" -b "Samsung-TVPlus XML data was last updated $(date -d @$staleXML -Iseconds)" "$appriseURL" && echo "$(date +"%Y-%m-%d %H:%M:%S") - Notification(s) sent via Apprise" >> $logFile

  { printf "%s" "$(date)"; echo -e " - Samsung-TVPlus last updated $(date -d @$staleXML -Iseconds)"; } >> $logFile

  touch $runFile
  [[ $runInterval == "once" ]] \
    && exit 0 \
    || sleep $runInterval
done
