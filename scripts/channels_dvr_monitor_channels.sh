#!/bin/bash
# channels_dvr_monitor_channels.sh
# 2026.01.07

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
foregroundScript=channels_dvr_monitor_channels
runningScriptPID=$(ps -ef | grep "[p]ython3 .* -i $channelsHost -p $channelsPort" | awk '{print $2}')
#greenIcon=\"icons\/channels.png\"
greenIcon=\"custom-webui\/icons\/channels.png\"
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
    serverHost=$(echo $server | awk -F: '{print $1}')
    serverPort=$(echo $server | awk -F: '{print $2}')
    activeProcess=$(ps -ef | grep "[p]ython3 .* -i $serverHost -p $serverPort" | awk '{print $2}')
    if [[ -n $activeProcess ]]; then
      echo "Background Channel Lineup Change Notifications process running for $server"
    fi
  done
}

scriptKill() {
  runningScriptPID=$(ps -ef | grep "[p]ython3 .* -i $channelsHost -p $channelsPort" | awk '{print $2}')
  kill $runningScriptPID
  rm /config/"$channelsHost"-"$channelsPort"_monitor_channels.running
  echo "Killing Channel Lineup Change Notifications PID $runningScriptPID"
  sleep 2
  lastActive=$(ps -e | grep python3 | awk '{print $1}')

  if [[ -z $lastActive ]]; then
    sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" $configTemp
    sed -i "/#${foregroundScript} title/s/(.*) #/#/" $configTemp
    sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: 30 #/" $configTemp
    sed -i "/#${foregroundScript} email default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} recipient default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} text default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} start default/s/default: .* #/default: none #/" $configTemp
    exit 0
  fi

  runningScripts
  exit 0
}

cp $configFile /tmp
frequency=$2
  [[ "$frequency" == "0" ]] && scriptKill
  [[ "$frequency" != "0" ]] \
  && sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: ${frequency} #/" $configTemp
email=$3
  [[ "$email" != "none" ]] && optionalArguments="-e $email" \
  && sed -i "/#${foregroundScript} email default/s/default: .* #/default: ${email} #/" $configTemp
password=${4// /}
  [[ "$password" != "none" ]] && optionalArguments="$optionalArguments -P $password"
recipient=$5
  [[ "$recipient" != "none" ]] && optionalArguments="$optionalArguments -r $recipient" \
  && sed -i "/#${foregroundScript} recipient default/s/default: .* #/default: ${recipient} #/" $configTemp
text=$6
  [[ "$text" != "none" ]] && optionalArguments="$optionalArguments -t $text" \
  && sed -i "/#${foregroundScript} text default/s/default: .* #/default: ${text} #/" $configTemp
start=$7
  [[ "$start" != "none" ]] && optionalArguments="$optionalArguments -s $start" \
  && sed -i "/#${foregroundScript} start default/s/default: .* #/default: ${start} #/" $configTemp

scriptRun() {
  runningScriptPID=$(ps -ef | grep "[p]ython3 .* -i $channelsHost -p $channelsPort" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && kill $runningScriptPID && echo "Killing currently running script with PID $runningScriptPID" \
  && sed -i "/#${foregroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
  && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp
  nohup python3 -u /config/$foregroundScript.py -i $channelsHost -p $channelsPort -f $frequency $optionalArguments >> $logFile 2>&1 &
  runningScriptPID=$!
  echo "$foregroundScript.sh $dvr $frequency $email $password $recipient $text $start" > /config/"$channelsHost"-"$channelsPort"_monitor_channels.running

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
