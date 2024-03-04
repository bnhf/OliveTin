#!/bin/bash

#set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_comskipini_latest.log
min_commercial_break_at_start_or_end="$2"
  [[ "$min_commercial_break_at_start_or_end" == "default" ]] && min_commercial_break_at_start_or_end=""
always_keep_first_seconds="$3"
  [[ "$always_keep_first_seconds" == "default" ]] && always_keep_first_seconds=""
always_keep_last_seconds="$4"
  [[ "$always_keep_last_seconds" == "default" ]] && always_keep_last_seconds=""
min_show_segment_length="$5"
  [[ "$min_show_segment_length" == "default" ]] && min_show_segment_length=""
min_commercialbreak="$6"
  [[ "$min_commercialbreak" == "default" ]] && min_commercialbreak=""
thread_count="$7"
  [[ "$thread_count" == "default" ]] && thread_count=""
dvrDir="$channelsHost-$channelsPort"

xputOptions=( "min_commercial_break_at_start_or_end" "always_keep_first_seconds" "always_keep_last_seconds" )

for xputOption in "${xputOptions[@]}"; do
  [[ -n ${!xputOption} ]] && curl -XPUT http://$dvr/comskip/ini/$xputOption/${!xputOption}
  #echo "$xputOption/${!xputOption}"
done

echo -e "\nCurrent CDVR Comskip status:" > $logFile
curl http://$dvr/comskip >> $logFile

echo -e "\n\nSettings as used in the most recent Comskip run. Assumes no override file in use:" >> $logFile
comskipLatest=$(find /mnt/$channelsHost-$channelsPort/Logs/comskip -name "comskip.ini" -exec ls -lt {} + 2>/dev/null | head -n 1)
comskipLatest=$(echo "$comskipLatest" | awk '{print $NF}')
echo -e "\nCurrent compskip.ini:" >> $logFile
echo "----------------------------------------" >> $logFile
cat $comskipLatest >> $logFile
echo "----------------------------------------" >> $logFile
comskipNew=$(cat $comskipLatest)

echo -e "\nIf you need to use an override file it should be placed in this directory on your CDVR server:" >> "$logFile"
/config/logfilter.sh $dvr 100000 "[SYS] Starting Channels DVR" | awk -F' in ' '{print $2; exit}' 1>> "$logFile"

overrideOptions=( "min_show_segment_length" "min_commercialbreak" "thread_count" )

for overrideOption in "${overrideOptions[@]}"; do
  [[ -n ${!overrideOption} ]] && comskipNew=$(echo "$comskipNew" | sed '/'"$overrideOption"'/c\'"$overrideOption"'='"${!overrideOption}"'')
done

echo -e "\nSave this text as compskip.ini in the location referenced above:" >> $logFile
echo "----------------------------------------" >> $logFile
echo "$comskipNew" >> "$logFile"
echo "----------------------------------------" >> $logFile
cat "$logFile"