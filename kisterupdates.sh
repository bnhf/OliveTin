#!/bin/bash

set -x

dvr="$1"
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
foregroundScript=kisterupdates
runningScriptPID=$(ps -ef | grep "[k]isterupdater.sh $dvr" | awk '{print $2}')
greenIcon=\"icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"
logFile=/config/"$channelsHost"-"$channelsPort"_"$foregroundScript"_latest.log
  rm $logFile
configFile=/config/config.yaml
configTemp=/tmp/config.yaml

#Trap end of script run
finish() {
  cp $configTemp /config
}

trap finish EXIT

runningScripts() {
  servers=($CHANNELS_DVR $CHANNELS_DVR_ALTERNATES)

  for server in "${servers[@]}"; do
    activeProcess=$(ps -ef | grep "[k]isterupdater.sh $server" | awk '{print $2}')
    if [[ -n $activeProcess ]]; then
      echo "Background Kister M3U Updater process running for $server"
    fi
  done
}

scriptKill() {
  runningScriptPID=$(ps -ef | grep "[k]isterupdater.sh $dvr" | awk '{print $2}')
  pkill -TERM -P $runningScriptPID
  kill $runningScriptPID
  rm /config/"$channelsHost"-"$channelsPort"_kisterupdates.running
  echo "Killing Kister M3U Updater PID $runningScriptPID"
  sleep 2
  lastActive=$(ps -e | grep kisterupdater | awk '{print $1}')

  if [[ -z $lastActive ]]; then
    sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" $configTemp
    sed -i "/#${foregroundScript} title/s/(.*) #/#/" $configTemp
    sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: 30m #/" $configTemp
    sed -i "/#${foregroundScript} m3u_name default/s/default: .* #/default: ah4c #/" $configTemp
    exit 0
  fi

  runningScripts
  exit 0
}

cp $configFile /tmp
frequency="$2"
  [[ "$frequency" == "0" ]] && scriptKill
  [[ "$frequency" != "0" ]] \
  && sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: ${frequency} #/" $configTemp
m3uName="$3"

scriptRun() {
  runningScriptPID=$(ps -ef | grep "[k]isterupdater.sh $dvr" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && kill $runningScriptPID && echo "Killing currently running script with PID $runningScriptPID" \
  && sed -i "/#${foregroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
  && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp
  nohup /config/kisterupdater.sh $dvr $frequency $m3uName >> $logFile 2>&1 &
  runningScriptPID=$!
  echo "$foregroundScript.sh $dvr $frequency $m3uName" > /config/"$channelsHost"-"$channelsPort"_kisterupdates.running

  grep -q '(.*) #'"$foregroundScript"'' $configTemp
    [[ "$?" == "1" ]] \
    && sed -i "/#${foregroundScript} title/s/#/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
    && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp

  sleep 2
  cat $logFile

  runningScripts
}

main() {
  cd /config
  scriptRun
}

main
