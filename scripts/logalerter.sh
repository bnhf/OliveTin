#!/bin/bash
# logalerter.sh
# 2025.05.05

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
filter4="$6"
  [[ "$filter4" != "none" ]] && filter4="$(echo "$filter4|")" || filter4=""
filter5="$7"
  [[ "$filter5" != "none" ]] && filter5="$(echo "$filter5|")" || filter5=""
read -a appriseURLs <<< "$8"
logFile=/config/"$channelsHost"-"$channelsPort"_logalerter_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
tailFile=/config/"$channelsHost"-"$channelsPort"_logalerter_tail.log
cdvrLogFile=/mnt/"$channelsHost"-"$channelsPort"_logs/data/channels-dvr.log

filters=( "$filter1" "$filter2" "$filter3" "$filter4" "$filter5" )
grepFilters=""

buildFilter() {
  for filter in "${filters[@]}"; do
    grepFilters="$(echo "$grepFilters""$filter")"
  done

  grepFilters="${grepFilters%|}"
  grepFilters=$(echo $grepFilters | sed 's/[][\.*^$(){}?+/]/\\&/g')
}

logAlerts() {
  tail -f $cdvrLogFile | grep --line-buffered -E "$grepFilters" >> $tailFile &

  while true; do
    if [ -s $tailFile ]; then
      echo "Log lines matching filters found using: grep --line-buffered -E $grepFilters" >> $logFile
      cat $tailFile >> $logFile
      for appriseURL in "${appriseURLs[@]}"; do
        case "$appriseURL" in
          channels://*)
            reminderTimeout="${appriseURL#channels://}"
            reminderTimeout="${reminderTimeout:-40}"
            /config/notifications.sh "OliveTin Log Alerts" "$(echo -e "$filter1\n $filter2\n $filter3\n $filter4\n $filter5")" "$reminderTimeout" && echo "$(date +"%Y-%m-%d %H:%M:%S") - Notification(s) sent via Channels API" >> $logFile
            ;;
          olivetin://) {
            echo -e "Subject: OliveTin Log Alert for $dvr\n"
            echo -e "The following CDVR ($dvr) log lines match your filters:\n"
            cat $tailFile
            } | msmtp -a default $ALERT_EMAIL_TO && echo "$(date +"%Y-%m-%d %H:%M:%S") - Notification(s) sent via OliveTin alerts" >> $logFile
            ;;
          *)
            apprise -t "OliveTin Log Alert for $dvr" -b "$(cat $tailFile)" "$appriseURL" && echo "$(date +"%Y-%m-%d %H:%M:%S") - Notification(s) sent via Apprise" >> $logFile
            ;;
        esac
      done
      truncate -s 0 $tailFile && echo "$(date +"%Y-%m-%d %H:%M:%S") - All notification(s) sent and tailFile truncated" >> $logFile
    fi
    sleep $runInterval
  done
}

main() {
  buildFilter
  logAlerts
}

main
