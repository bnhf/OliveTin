#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
foregroundScript=channels_dvr_monitor_channels
runningScriptPID=$(ps -ef | grep "[p]ython3 .* -i $channelsHost -p $channelsPort" | awk '{print $2}')
greenIcon=\"icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"

#Trap end of script run
finish() {
  #echo "$foregroundScript.sh is exiting with exit code $?"
  cp /config/config.yaml /config/temp.yaml && cp /config/temp.yaml /config/config.yaml
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
    sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" /config/config.yaml
    sed -i "/#${foregroundScript} title/s/(.*) #/#/" /config/config.yaml
    sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: 30 #/" /config/config.yaml
    sed -i "/#${foregroundScript} email default/s/default: .* #/default: none #/" /config/config.yaml
    sed -i "/#${foregroundScript} recipient default/s/default: .* #/default: none #/" /config/config.yaml
    sed -i "/#${foregroundScript} text default/s/default: .* #/default: none #/" /config/config.yaml
    exit 0
  fi

  runningScripts
  exit 0
}

frequency=$2
  [[ "$frequency" == "0" ]] && scriptKill
  [[ "$frequency" != "0" ]] \
  && sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: ${frequency} #/" /config/config.yaml
email=$3
  [[ "$email" != "none" ]] && optionalArguments="-e $email" \
  && sed -i "/#${foregroundScript} email default/s/default: .* #/default: ${email} #/" /config/config.yaml
password=${4// /}
  [[ "$password" != "none" ]] && optionalArguments="$optionalArguments -P $password"
recipient=$5
  [[ "$recipient" != "none" ]] && optionalArguments="$optionalArguments -r $recipient" \
  && sed -i "/#${foregroundScript} recipient default/s/default: .* #/default: ${recipient} #/" /config/config.yaml
text=$6
  [[ "$text" != "none" ]] && optionalArguments="$optionalArguments -t $text" \
  && sed -i "/#${foregroundScript} text default/s/default: .* #/default: ${text} #/" /config/config.yaml

scriptRun() {
  runningScriptPID=$(ps -ef | grep "[p]ython3 .* -i $channelsHost -p $channelsPort" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && kill $runningScriptPID && echo "Killing currently running script with PID $runningScriptPID" \
  && sed -i "/#${foregroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" /config/config.yaml \
  && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" /config/config.yaml
  nohup python3 -u /config/$foregroundScript.py -i $channelsHost -p $channelsPort -f $frequency $optionalArguments > /config/"$channelsHost"-"$channelsPort"_monitor_channels.log 2>&1 &
  runningScriptPID=$!
  echo "$foregroundScript.sh $dvr $frequency $email $password $recipient $text" > /config/"$channelsHost"-"$channelsPort"_monitor_channels.running

  grep -q '(.*) #'"$foregroundScript"'' /config/config.yaml
    [[ "$?" == "1" ]] \
    && sed -i "/#${foregroundScript} title/s/#/($(date +'%d%b%y_%H:%M')) #/" /config/config.yaml \
    && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" /config/config.yaml

  sleep 2
  cat /config/"$channelsHost"-"$channelsPort"_monitor_channels.log

  runningScripts
}

main() {
  scriptRun
}

main