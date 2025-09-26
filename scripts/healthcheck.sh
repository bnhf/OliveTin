#!/bin/bash
# healthcheck.sh
# 2025.09.15

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
hostHealthcheck=$2
  [[ $hostHealthcheck == 0 ]] && hostHealthcheck=""
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_healthcheck-olivetin_latest.log
healthcheck="/config/fifopipe_containerside.sh"

containerHealthcheck() {
  echo -e "Checking your OliveTin-for-Channels installation..." > $logFile
  [[ $hostHealthcheck ]] && echo -e "(extended_check=true)\n" >> $logFile || echo -e "(extended_check=false)\n" >> $logFile

  olivetinVersion=$(grep "pageTitle:" /config/config.yaml | awk '{print $3}') && echo -e "OliveTin Container Version $olivetinVersion" >> $logFile
  echo -e "OliveTin Docker Compose Version $OLIVETIN_COMPOSE\n" >> $logFile
  [[ $EZ_START ]] && echo -e "Warning the EZ_START env var is still set. This needs to be removed for production use!" >> $logFile
  
  echo -e "----------------------------------------\n" >> $logFile

  echo -e "Checking that your selected Channels DVR server ($dvr) is reachable by URL:" >> $logFile
  echo -e "HTTP Status: 200 indicates success...\n" >> $logFile
  curlDVR=$(curl --fail --output /dev/null --max-time 5 -w "HTTP Status: %{http_code}\nEffective URL: %{url_effective}\n" http://$dvr 2>&1)
  echo -e "$curlDVR\n" >> $logFile

  echo -e "----------------------------------------\n" >> $logFile

  echo -e "Checking that your selected Channels DVR server's data files (/mnt/$channelsHost-$channelsPort) are accessible:" >> $logFile
  echo -e "Folders with the names Database, Images, Imports, Logs, Movies, Streaming and TV should be visible...\n" >> $logFile
  ls -la /mnt/$channelsHost-$channelsPort  >> $logFile
  
  olivetinDockerJSON=$(docker inspect --format '{{ json .Mounts }}' olivetin | jq)
  dvrShareInspect=$(echo $olivetinDockerJSON | jq -r '.[] | select(.Destination == "/mnt/'"$channelsHost"'-'"$channelsPort"'") | .Source')
    echo -e "\nDocker reports your current DVR_SHARE setting as..." >> $logFile
    echo "$dvrShareInspect" >> $logFile
    
  echo -e "\nIf the listed folders are NOT visible, AND you have your Channels DVR and Docker on the same system:\n" >> $logFile

  echo -e "Channels reports this path as..." >> $logFile
  dvrShare=$(curl -s http://$dvr/dvr | jq -r '.path' | tee -a $logFile)
  
  #dvrShare=/home/test && echo "$dvrShare" >> $logFile
  [[ $dvrShare == *\\* ]] && windowsOS=true || windowsOS=""
  [[ $windowsOS ]] && dvrShare=$(echo "$dvrShare" | sed 's|\\|/|g') #\
    #&& echo -e "\nWhen using a Windows path in Portainer, change the backslashes to slashes like this...\n$dvrShare\n" >> $logFile
  [[ $windowsOS ]] && dvrShare=$(echo "$dvrShare" | sed -E 's|^([A-Za-z]):|/mnt/\L\1|') \
    && echo -e "\nWhen using WSL with a Linux distro and Docker Desktop, it's recommended to use...\n$dvrShare" >> $logFile

  echo -e "\n----------------------------------------\n" >> $logFile

  echo -e "Checking that your selected Channels DVR server's log files (/mnt/"$channelsHost"-"$channelsPort"_logs) are accessible:" >> $logFile
  echo -e "Folders with the names data and latest should be visible...\n" >> $logFile
  ls -la /mnt/"$channelsHost"-"$channelsPort"_logs  >> $logFile

  logsShareInspect=$(echo $olivetinDockerJSON | jq -r '.[] | select(.Destination == "/mnt/'"$channelsHost"'-'"$channelsPort"'_logs") | .Source')
    echo -e "\nDocker reports your current LOGS_SHARE setting as..." >> $logFile
    echo "$logsShareInspect" >> $logFile

  echo -e "\nIf the listed folders are NOT visible, AND you have your Channels DVR and Docker on the same system:\n" >> $logFile
  echo -e "Channels reports this path as..." >> $logFile
  logsShare=$(curl -s http://$dvr/log?n=100000 | grep -m 1 "Starting Channels DVR" | awk -F ' in ' '{print $2}' | awk '{sub(/[\\/]?data$/, ""); print}' | tee -a $logFile)
  #logsShare=/home/test && echo "$logsShare" >> $logFile
  [[ $logsShare == *\\* ]] && windowsOS=true || windowsOS=""
  [[ $windowsOS ]] && logsShare=$(echo "$logsShare" | sed 's|\\|/|g') #\
    #&& echo -e "\nWhen using a Windows path in Portainer, change the backslashes to slashes like this...\n$logsShare\n" >> $logFile
  [[ $windowsOS ]] && logsShare=$(echo "$logsShare" | sed -E 's|^([A-Za-z]):|/mnt/\L\1|') \
    && echo -e "\nWhen using WSL with a Linux distro and Docker Desktop, it's recommended to use...\n$logsShare" >> $logFile

  echo -e "\n----------------------------------------\n" >> $logFile

  echo -e "Checking if your Portainer token is working on ports 9000 and/or 9443:\n" >> $logFile
  [[ -z $PORTAINER_PORT ]] && portainerPort=9443 || portainerPort=$PORTAINER_PORT
  portainerName="${PORTAINER_NAME:-local}"
  echo "Portainer http response on port 9000 reports version $(curl -s -k --max-time 3 -H "Authorization: Bearer ${PORTAINER_TOKEN}" http://$PORTAINER_HOST:9000/api/status | jq -r '.Version')" >> $logFile
  echo "Portainer Environment ID for $portainerName is $(curl -s -k -X GET --max-time 3 -H "X-API-Key: $PORTAINER_TOKEN" "http://$PORTAINER_HOST:9000/api/endpoints" | jq --arg portainerName "$portainerName" '.[] | select(.Name==$portainerName) | .Id')" >> $logFile
  echo "Portainer https response on port $portainerPort reports version $(curl -s -k --max-time 3 -H "Authorization: Bearer ${PORTAINER_TOKEN}" https://$PORTAINER_HOST:$portainerPort/api/status | jq -r '.Version')" >> $logFile
  echo "Portainer Environment ID for $portainerName is $(curl -s -k -X GET --max-time 3 -H "X-API-Key: $PORTAINER_TOKEN" "https://$PORTAINER_HOST:$portainerPort/api/endpoints" | jq --arg portainerName "$portainerName" '.[] | select(.Name==$portainerName) | .Id')" >> $logFile

  echo -e "\n----------------------------------------\n" >> $logFile

  echo -e "Here's a list of your current OliveTin-related settings:\n" >> $logFile
  echo "HOSTNAME=$HOSTNAME" >> $logFile
  echo "CHANNELS_DVR=$CHANNELS_DVR" >> $logFile
  echo "CHANNELS_DVR_ALTERNATES=$CHANNELS_DVR_ALTERNATES" >> $logFile
  echo "CHANNELS_CLIENTS=$CHANNELS_CLIENTS" >> $logFile
  echo "ALERT_SMTP_SERVER=$ALERT_SMTP_SERVER" >> $logFile
  echo "$ALERT_EMAIL_FROM" | awk -F@ '{print "ALERT_EMAIL_FROM=[Redacted]@" $2}' >> $logFile
  [[ ALERT_EMAIL_PASS ]] && echo "ALERT_EMAIL_PASS=[Redacted]" >> $logFile
  echo "$ALERT_EMAIL_TO" | awk -F@ '{print "ALERT_EMAIL_TO=[Redacted]@" $2}' >> $logFile
  echo "UPDATE_YAMLS=$UPDATE_YAMLS" >> $logFile
  echo "UPDATE_SCRIPTS=$UPDATE_SCRIPTS" >> $logFile
  [[ $PORTAINER_TOKEN ]] && echo "PORTAINER_TOKEN=[Redacted]" >> $logFile
  echo "PORTAINER_HOST=$PORTAINER_HOST" >> $logFile
  echo "PORTAINER_PORT=$PORTAINER_PORT" >> $logFile
  echo "PORTAINER_ENV=$PORTAINER_ENV" >> $logFile

  echo -e "\n----------------------------------------\n" >> $logFile

  echo -e "Here's the contents of /etc/resolv.conf from inside the container:\n" >> $logFile
  sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' /etc/resolv.conf >> $logFile

  echo -e "\n----------------------------------------\n" >> $logFile

  echo -e "Here's the contents of /etc/hosts from inside the container:\n" >> $logFile
  cat /etc/hosts >> $logFile
}

determineHostOS() {
  wsl=$($healthcheck WSL_DISTRO_NAME)
  [[ -z $wsl ]] && linux=$($healthcheck LINUX_DISTRO_NAME | awk -F= '/PRETTY_NAME/ {print $2}')
  [[ -z $linux ]] && linux=$($healthcheck LINUX_DISTRO_NAME | awk -F= '/os_name/ {print $2}')
}

linuxHealthcheck() {
  echo -e "\n----------------------------------------\n" >> $logFile

  echo -e "Your Docker-host is running:\n\n $linux" >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile
  
  echo -e "\nYour Docker-host's /etc/resolv.conf file contains:\n" >> "$logFile"
  $healthcheck resolv.conf | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' >> "$logFile"
  
  echo -e "\n----------------------------------------" >> $logFile
  
  echo -e "\nYour Docker-host's /etc/hosts file contains:\n" >> "$logFile"
  $healthcheck hosts | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' \
                     >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile

  echo -e "\nYour Tailscale version is:\n" >> $logFile
  $healthcheck tailscale_version >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile
}

wslHealthcheck() {
  echo -e "\n----------------------------------------\n" >> $logFile

  echo -e "Your WSL Docker-host is running:\n\n $wsl" >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile
  
  echo -e "\nYour WSL Docker-host's /etc/resolv.conf file contains:\n" >> "$logFile"
  $healthcheck resolv.conf | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' >> "$logFile"
  
  echo -e "\n----------------------------------------" >> $logFile
  
  echo -e "\nYour WSL Docker-host's /etc/hosts file contains:\n" >> "$logFile"
  $healthcheck hosts | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' \
                     >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile
  
  echo -e "\nYour WSL Docker-host's /etc/wsl.conf file contains:\n" >> "$logFile"
  $healthcheck wsl.conf >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile
  
  echo -e "\nYour Windows PC's %USERPROFILE%\.wslconfig file contains:\n" >> "$logFile"
  $healthcheck .wslconfig >> "$logFile"

  echo -e "\n\n----------------------------------------" >> $logFile
  
  echo -e "\nYour Windows PC's etc/hosts file contains:\n" >> "$logFile"
  $healthcheck windows_hosts >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile
  
  echo -e "\nYour Windows PC's DNS server resolution:\n" >> "$logFile"
  domain=$(grep search /etc/resolv.conf | awk '{print $2}')
  $healthcheck "nslookup" "$channelsHost.$domain" | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' \
                                                  | sed '/Name/{n;s/^Address:  100\..*/Address:  100.[Redacted]/;}' \
                                                  >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile
  
  echo -e "\nYour Windows PC's network interfaces:\n" >> "$logFile"
  $healthcheck windows_ipconfig | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' \
                                | sed 's/^\([[:space:]]*\)Physical Address.*/\1Physical Address. . . . . . . . . : [Redacted]/' \
                                | sed 's/^\([[:space:]]*\)IPv6 Address.*/\1IPv6 Address. . . . . . . . . . . : [Redacted]/' \
                                | sed 's/^\([[:space:]]*\)Temporary IPv6 Address.*/\1Temporary IPv6 Address. . . . . . : [Redacted]/' \
                                | sed 's/^\([[:space:]]*\)Link-local IPv6 Address.*/\1Link-local IPv6 Address . . . . . : [Redacted]/' \
                                | sed 's/^\([[:space:]]*\)IPv4 Address. . . . . . . . . . . : 100\..*/\1IPv4 Address. . . . . . . . . . . : 100.[Redacted]/' \
                                | sed 's/^\([[:space:]]*\)DHCPv6 IAID.*/\1DHCPv6 IAID . . . . . . . . . . . : [Redacted]/' \
                                | sed 's/^\([[:space:]]*\)DHCPv6 Client DUID.*/\1DHCPv6 Client DUID. . . . . . . . : [Redacted]/' \
                                >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile

  echo -e "\nYour Tailscale version is:\n" >> $logFile
  $healthcheck windows_tailscale_version >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile
}

closePipe() {
  $healthcheck END_OF_RUN > /dev/null
}

main() {
  containerHealthcheck
  [[ $hostHealthcheck ]] && determineHostOS
  [[ $hostHealthcheck && $wsl ]] && wslHealthcheck && closePipe
  [[ $hostHealthcheck && $linux ]] && linuxHealthcheck && closePipe
  cat $logFile
}

main
