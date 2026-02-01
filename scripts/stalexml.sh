#!/bin/bash
# stalexml.sh
# 2026.01.07

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr="$1"
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
foregroundScript=stalexml
runningScriptPID=$(ps -ef | grep "[s]talexmlalerter.sh $dvr" | awk '{print $2}')
#greenIcon=\"icons\/channels.png\"
greenIcon=\"custom-webui\/icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"
logFile=/config/"$channelsHost"-"$channelsPort"_"$foregroundScript"_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
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
    activeProcess=$(ps -ef | grep "[s]talexmlalerter.sh $server" | awk '{print $2}')
    if [[ -n $activeProcess ]]; then
      echo -e "Background Stale XML process running for $server"
    fi
  done
}

scriptKill() {
  runningScriptPID=$(ps -ef | grep "[s]talexmlalerter.sh $dvr" | awk '{print $2}')
  pkill -TERM -P $runningScriptPID
  kill $runningScriptPID
  rm /config/"$channelsHost"-"$channelsPort"_stalexml.running
  echo "Killing Stale XML PID $runningScriptPID"
  sleep 2
  lastActive=$(ps -e | grep stalexmlalerter | awk '{print $1}')

  if [[ -z $lastActive ]]; then
    sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" $configTemp
    sed -i "/#${foregroundScript} title/s/(.*) #/#/" $configTemp
    sed -i "/#${foregroundScript} interval default/s/default: .* #/default: 1h #/" $configTemp
    sed -i "/#${foregroundScript} xml_url default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} staleness default/s/default: .* #/default: 3h #/" $configTemp
    sed -i "/#${foregroundScript} apprise_url default/s/default: .* #/default: none #/" $configTemp
    exit 0
  fi

  runningScripts
  exit 0
}

cp $configFile /tmp
interval="$2"
  [[ "$interval" == "0" ]] && scriptKill
  [[ "$interval" != "0" ]] \
  && sed -i "/#${foregroundScript} interval default/s/default: .* #/default: ${interval} #/" $configTemp
xmlURL="$3"
  [[ "$xmlURL" != "none" ]] \
  && sed -i "/#${foregroundScript} xml_url default/s|default: .* #|default: ${xmlURL} #|" $configTemp
staleness="$4"
  [[ "$staleness" != "3h" ]] \
  && sed -i "/#${foregroundScript} staleness default/s/default: .* #/default: ${staleness} #/" $configTemp
appriseURL="$5"
  [[ "$appriseURL" != "none" ]] \
  && sed -i "/#${foregroundScript} apprise_url default/s|default: .* #|default: ${appriseURL} #|" $configTemp

scriptRun() {
  runningScriptPID=$(ps -ef | grep "[s]talexmlalerter.sh $dvr" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && kill $runningScriptPID && echo "Killing currently running script with PID $runningScriptPID" \
  && sed -i "/#${foregroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
  && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp
  nohup /config/stalexmlalerter.sh $dvr $interval $xmlURL $staleness $appriseURL >> $logFile 2>&1 &
  runningScriptPID=$!
  echo "$foregroundScript.sh $dvr $interval $xmlURL $staleness $appriseURL" > /config/"$channelsHost"-"$channelsPort"_stalexml.running

  grep -q '(.*) #'"$foregroundScript"'' $configTemp
    [[ "$?" == "1" ]] \
    && sed -i "/#${foregroundScript} title/s/#/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
    && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp

  sleep 4
  cat $logFile

  runningScripts
}

main() {
  cd /config
  scriptRun
}

main
