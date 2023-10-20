#!/bin/bash

set -x

foregroundScript=channels_dvr_monitor_channels
runningScriptPID=$(ps -e | grep python3 | awk '{print $1}')
greenIcon=\"icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"

#Trap end of script run
finish() {
  #echo "$foregroundScript.sh is exiting with exit code $?"
  cp /config/config.yaml /config/temp.yaml && cp /config/temp.yaml /config/config.yaml
}

trap finish EXIT

scriptKill() {
  runningScriptPID=$(ps -e | grep python3 | awk '{print $1}')
  kill $runningScriptPID
  rm /config/$foregroundScript.running
  echo "Killing Channel Lineup Change Notifications PID $runningScriptPID"
  sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" /config/config.yaml
  sed -i "/#${foregroundScript} title/s/(.*) #/#/" /config/config.yaml
  sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: 30 #/" /config/config.yaml
  sed -i "/#${foregroundScript} email default/s/default: .* #/default: none #/" /config/config.yaml
  sed -i "/#${foregroundScript} recipient default/s/default: .* #/default: none #/" /config/config.yaml
  sed -i "/#${foregroundScript} text default/s/default: .* #/default: none #/" /config/config.yaml

  exit 0
}

frequency=$1
  [[ "$frequency" == "0" ]] && scriptKill
  [[ "$frequency" != "0" ]] \
  && sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: ${frequency} #/" /config/config.yaml
email=$2
  [[ "$email" != "none" ]] && optionalArguments="-e $email" \
  && sed -i "/#${foregroundScript} email default/s/default: .* #/default: ${email} #/" /config/config.yaml
password=${3// /}
  [[ "$password" != "none" ]] && optionalArguments="$optionalArguments -P $password"
recipient=$4
  [[ "$recipient" != "none" ]] && optionalArguments="$optionalArguments -r $recipient" \
  && sed -i "/#${foregroundScript} recipient default/s/default: .* #/default: ${recipient} #/" /config/config.yaml
text=$5
  [[ "$text" != "none" ]] && optionalArguments="$optionalArguments -t $text" \
  && sed -i "/#${foregroundScript} text default/s/default: .* #/default: ${text} #/" /config/config.yaml

channelsHost=$(echo $CHANNELS_DVR | awk -F: '{print $1}')
channelsPort=$(echo $CHANNELS_DVR | awk -F: '{print $2}')

scriptRun() {
  runningScriptPID=$(ps -e | grep python3 | awk '{print $1}')
  [[ -n $runningScriptPID ]] && kill $runningScriptPID && echo "Killing currently running script with PID $runningScriptPID" \
  && sed -i "/#${foregroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" /config/config.yaml \
  && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" /config/config.yaml
  nohup python3 -u /config/$foregroundScript.py -i $channelsHost -p $channelsPort -f $frequency $optionalArguments > /config/$foregroundScript.log 2>&1 &
  runningScriptPID=$!
  echo "$foregroundScript.sh $frequency $email $password $recipient $text" > /config/$foregroundScript.running

  grep -q '(.*) #'"$foregroundScript"'' /config/config.yaml
    [[ "$?" == "1" ]] \
    && sed -i "/#${foregroundScript} title/s/#/($(date +'%d%b%y_%H:%M')) #/" /config/config.yaml \
    && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" /config/config.yaml

  sleep 2
  cat /config/$foregroundScript.log
}

main() {
  scriptRun
}

main