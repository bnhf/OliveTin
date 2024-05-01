#!/bin/bash

set -x

dvr=$1
hostHealthcheck=$2
  [[ $hostHealthcheck == 0 ]] && hostHealthcheck=""
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_healthcheck-olivetin_latest.log
healthcheck="/config/fifopipe_containerside.sh"

containerHealthcheck() {
  echo -e "Checking your OliveTin installation..." > $logFile
  [[ $hostHealthcheck ]] && echo -e "(extended_check=true)\n" >> $logFile || echo -e "(extended_check=false)\n" >> $logFile

  echo -e "----------------------------------------\n" >> $logFile

  echo -e "Checking that your selected Channels DVR server ($dvr) is reachable by URL:" >> $logFile
  echo -e "HTTP Status: 200 indicates success...\n" >> $logFile
  curlDVR=$(curl --fail --output /dev/null --max-time 5 -w "HTTP Status: %{http_code}\nEffective URL: %{url_effective}\n" http://$dvr 2>&1)
  echo -e "$curlDVR\n" >> $logFile

  echo -e "----------------------------------------\n" >> $logFile

  echo -e "Checking that your selected Channels DVR server's data files (/mnt/$channelsHost-$channelsPort) are accessible:" >> $logFile
  echo -e "Folders with the names Database, Images, Imports, Logs, Movies, Streaming and TV should be visible...\n" >> $logFile
  ls -la /mnt/$channelsHost-$channelsPort  >> $logFile

  echo -e "\n----------------------------------------\n" >> $logFile

  echo -e "Checking that your selected Channels DVR server's log files (/mnt/"$channelsHost"-"$channelsPort"_logs) are accessible:" >> $logFile
  echo -e "Folders with the names data and latest should be visible...\n" >> $logFile
  ls -la /mnt/"$channelsHost"-"$channelsPort"_logs  >> $logFile

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
