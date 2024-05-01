#!/bin/bash

#set -x

dvr="$1"
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval="$2"
  [[ "$runInterval" == "0" ]] && runInterval=""
filter1="$3"
  [[ "$filter1" != "none" ]] && filter1="$(echo "$filter1|")" || filter1=""
filter2="$4"
  [[ "$filter2" != "none" ]] && filter2="$(echo "$filter2|")" || filter2=""
filter3="$5"
  [[ "$filter3" != "none" ]] && filter3="$(echo "$filter3|")" || filter3=""
logFile=/config/"$channelsHost"-"$channelsPort"_logalerter_latest.log
cdvrLogFile=/mnt/"$channelsHost"-"$channelsPort"_logs/data/channels-dvr.log

filters=( "$filter1" "$filter2" "$filter3" )
grepFilters=""

buildFilter() {
  for filter in "${filters[@]}"; do
    grepFilters="$(echo "$grepFilters""$filter")"
  done

  grepFilters="${grepFilters%|}"
  grepFilters=$(echo $grepFilters | sed 's/[][\.*^$(){}?+/]/\\&/g')
}

logAlerts() {
  tail -f $cdvrLogFile | grep --line-buffered -E "$grepFilters" >> $logFile &

  while true; do
    if [ -s $logFile ]; then {
      echo -e "Subject: OliveTin Log Alert\n"
      echo -e "The following CDVR log lines match your filters:\n"
      cat $logFile
      } | msmtp -a default $ALERT_EMAIL_TO
      rm $logFile
    fi

    sleep $runInterval
  done
}

main() {
  buildFilter
  logAlerts
}

main
