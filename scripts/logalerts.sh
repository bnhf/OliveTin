#!/bin/bash
# logalerts.sh
# 2026.01.07

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr="$1"
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
foregroundScript=logalerts
runningScriptPID=$(ps -ef | grep "[l]ogalerter.sh $dvr" | awk '{print $2}')
#greenIcon=\"icons\/channels.png\"
greenIcon=\"custom-webui\/icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"
logFile=/config/"$channelsHost"-"$channelsPort"_"$foregroundScript"_latest.log
  [[ -f $logFile ]] && rm $logFile
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
    activeProcess=$(ps -ef | grep "[l]ogalerter.sh $server" | awk '{print $2}')
    if [[ -n $activeProcess ]]; then
      echo "Background E-Mail Log Alerts process running for $server"
    fi
  done
}

scriptKill() {
  runningScriptPID=$(ps -ef | grep "[l]ogalerter.sh $dvr" | awk '{print $2}')
  pkill -TERM -P $runningScriptPID
  kill $runningScriptPID
  rm /config/"$channelsHost"-"$channelsPort"_logalerts.running
  echo "Killing E-Mail Log Alerts PID $runningScriptPID"
  sleep 2
  lastActive=$(ps -e | grep logalerter | awk '{print $1}')

  if [[ -z $lastActive ]]; then
    sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" $configTemp
    sed -i "/#${foregroundScript} title/s/(.*) #/#/" $configTemp
    sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: 2m #/" $configTemp
    sed -i "/#${foregroundScript} filter1 default/s/default: .* #/default: \"[DVR] Error\" #/" $configTemp
    sed -i "/#${foregroundScript} filter2 default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} filter3 default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} filter4 default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} filter5 default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} apprise_url default/s|default: .* #|default: olivetin:// #|" $configTemp
    exit 0
  fi

  runningScripts
  exit 0
}

cp $configFile /tmp
frequency="$2"
  [[ "$frequency" == "once" ]] && echo "Run once mode not supported. Use Generate Filtered Channels DVR Log Action instead" \
    && exit 0
  [[ "$frequency" == "0" ]] && scriptKill
  [[ "$frequency" != "0" ]] \
  && sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: ${frequency} #/" $configTemp
filter1="$3"
  sed -i "/#${foregroundScript} filter1 default/s/default: .* #/default: \"${filter1}\" #/" $configTemp
filter2="$4"
  sed -i "/#${foregroundScript} filter2 default/s/default: .* #/default: \"${filter2}\" #/" $configTemp
filter3="$5"
  sed -i "/#${foregroundScript} filter3 default/s/default: .* #/default: \"${filter3}\" #/" $configTemp
filter4="$6"
  sed -i "/#${foregroundScript} filter4 default/s/default: .* #/default: \"${filter4}\" #/" $configTemp
filter5="$7"
  sed -i "/#${foregroundScript} filter5 default/s/default: .* #/default: \"${filter5}\" #/" $configTemp
apprise_url=$8
  [[ "$apprise_url" != "olivetin://" ]] \
  && sed -i "/#${foregroundScript} apprise_url default/s|default: .* #|default: ${apprise_url} #|" $configTemp

scriptRun() {
  runningScriptPID=$(ps -ef | grep "[l]ogalerter.sh $dvr" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && kill $runningScriptPID && echo "Killing currently running script with PID $runningScriptPID" \
  && sed -i "/#${foregroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
  && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp
  nohup /config/logalerter.sh $dvr $frequency "$filter1" "$filter2" "$filter3" "$filter4" "$filter5" "$apprise_url" >> $logFile 2>&1 &
  runningScriptPID=$!
  echo "$foregroundScript.sh $dvr $frequency \"$filter1\" \"$filter2\" \"$filter3\" \"$filter4\" \"$filter5\" \"$apprise_url\"" > /config/"$channelsHost"-"$channelsPort"_logalerts.running

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
