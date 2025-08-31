#!/bin/bash
# adbtuneralerts.sh
# 2025.05.05

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr="$1"
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
foregroundScript=adbtuneralerts
runningScriptPID=$(ps -ef | grep "[a]dbtuneralerter.sh $dvr" | awk '{print $2}')
greenIcon=\"icons\/channels.png\"
#greenIcon=\"custom-webui\/icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"
logFile=/config/"$channelsHost"-"$channelsPort"_"$foregroundScript"_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
configFile=/config/config.yaml
configTemp=/tmp/config.yaml

#Trap end of script run
finish() {
  #nohup /config/finish.sh $configTemp >> $logFile 2>&1 &
  cp $configTemp /config
}

trap finish EXIT

runningScripts() {
  servers=($CHANNELS_DVR $CHANNELS_DVR_ALTERNATES)

  for server in "${servers[@]}"; do
    activeProcess=$(ps -ef | grep "[a]dbtuneralerter.sh $server" | awk '{print $2}')
    if [[ -n $activeProcess ]]; then
      echo "Background ADBTuner Alerts process running for $server"
    fi
  done
}

scriptKill() {
  runningScriptPID=$(ps -ef | grep "[a]dbtuneralerter.sh $dvr" | awk '{print $2}')
  pkill -TERM -P $runningScriptPID
  kill $runningScriptPID
  rm /config/"$channelsHost"-"$channelsPort"_adbtuneralerts.running
  echo "Killing ADBTuner Alerts PID $runningScriptPID"
  sleep 2
  lastActive=$(ps -e | grep adbtuneralerter | awk '{print $1}')

  if [[ -z $lastActive ]]; then
    sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" $configTemp
    sed -i "/#${foregroundScript} title/s/(.*) #/#/" $configTemp
    sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: 30m #/" $configTemp
    sed -i "/#${foregroundScript} adbtuner_host_port default/s/default: .* #/default: docker-host:5592 #/" $configTemp
    sed -i "/#${foregroundScript} apprise_url default/s/default: .* #/default: none #/" $configTemp
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
adbtunerHostPort="$3"
  [[ "$adbtunerHostPort" != "docker-host:5592" ]] \
  && sed -i "/#${foregroundScript} adbtuner_host_port default/s|default: .* #|default: ${adbtunerHostPort} #|" $configTemp
appriseURL="$4"
  [[ "$appriseURL" != "none" ]] \
  && sed -i "/#${foregroundScript} apprise_url default/s|default: .* #|default: ${appriseURL} #|" $configTemp


scriptRun() {
  runningScriptPID=$(ps -ef | grep "[a]dbtuneralerter.sh $dvr" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && kill $runningScriptPID && echo "Killing currently running script with PID $runningScriptPID" \
  && sed -i "/#${foregroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
  && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp
  nohup /config/adbtuneralerter.sh $dvr $frequency $adbtunerHostPort $appriseURL >> $logFile 2>&1 &
  runningScriptPID=$!
  echo "$foregroundScript.sh $dvr $frequency $adbtunerHostPort $appriseURL" > /config/"$channelsHost"-"$channelsPort"_adbtuneralerts.running

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
