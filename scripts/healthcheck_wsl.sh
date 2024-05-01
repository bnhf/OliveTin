#! /bin/bash

requiredSyntax() {
  echo -e "\nThis script must be executed from the host directory bound to /config, with the required arguments, in the following format:" \
  && echo -e "sudo -E ./healthcheck_wsl.sh \"\$PATH\" \"Optional OliveTin Stack name <default=olivetin>\" 2>/dev/null\n" \
  && exit 0
}

[ $# -eq 0 ] && requiredSyntax
[[ -n "$1" ]] && export PATH="$1"
dvr=$(docker exec -it olivetin printenv | awk -F= '/CHANNELS_DVR=/ {print $2}')
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/tmp/healthcheck_wsl_latest.log
tmpFile=$(mktemp)
  cd /mnt/c/Windows > /dev/null
userName=$(cmd.exe /c whoami | awk -F\\ '{print $2}')
windowsHost=$(cmd.exe /c whoami | awk -F\\ '{print $1}')
  cd -
[[ -z $2 ]] && olivetinStackName="olivetin"

stackHealthcheck() {
  echo -e "\n----------------------------------------\n" > $logFile

  echo -e "Your current OliveTin Stack:\n" >> $logFile
  olivetinCompose=$(docker exec -it olivetin /config/healthcheck_stack.sh "$olivetinStackName" "$windowsHost" compose)
  echo -e "$olivetinCompose" >> $logFile

  echo -e "\nYour OliveTin Stack uses these environemnt variables:\n" >> $logFile
  olivetinEnvVars=$(docker exec -it olivetin /config/healthcheck_stack.sh "$olivetinStackName" "$windowsHost" envvars)
  echo -e "$olivetinEnvVars" | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' \
                             | sed '/PORTAINER_TOKEN/s/=.*/=[Redacted]/' \
                             >> $logFile
}

wslHealthcheck() {
  echo -e "\n----------------------------------------\n" >> $logFile

  echo -e "Your WSL Docker-host is running:\n\n $WSL_DISTRO_NAME" >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile
  
  echo -e "\nYour WSL Docker-host's /etc/resolv.conf file contains:\n" >> "$logFile"
  cat /etc/resolv.conf | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' >> "$logFile"
  
  echo -e "\n----------------------------------------" >> $logFile
  
  echo -e "\nYour WSL Docker-host's /etc/hosts file contains:\n" >> "$logFile"
  cat /etc/hosts | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' \
                 >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile
  
  echo -e "\nYour WSL Docker-host's /etc/wsl.conf file contains:\n" >> "$logFile"
  cat /etc/wsl.conf >> "$logFile"

  echo -e "----------------------------------------" >> $logFile
  
  echo -e "\nYour Windows PC's %USERPROFILE%\.wslconfig file contains:\n" >> "$logFile"
  cat "/mnt/c/Users/$userName/.wslconfig" 2>/dev/null >> "$logFile"

  echo -e "\n\n----------------------------------------" >> $logFile
  
  echo -e "\nYour Windows PC's etc/hosts file contains:\n" >> "$logFile"
  cat /mnt/c/Windows/System32/drivers/etc/hosts | tr -d '\r'| \
    awk '
    BEGIN {
        OFS=" ";
    }
    /^#/ || /^$/ {
        print $0;
    }
    !/^#/ && NF {
        printf "%-15s %-20s\n", $1, $2;
    }
    ' >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile

  cd /mnt/c/Windows

  echo -e "\nThe following adapter-specific domains are in-use on your LAN:\n" >> $logFile
  cmd.exe /c ipconfig /all | awk -F: '/Connection-specific DNS Suffix/ {print $2}' | grep '\S' | sed 's/^[ \t]*//' | tr -d '\r' | sed 's/\r$//' > $tmpFile
  cat $tmpFile | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' \
               >> $logFile

  echo -e "\n----------------------------------------" >> $logFile
  
  domains=$(cat $tmpFile)
  
  for domain in ${domains[@]}; do
    echo -e "\nYour Windows PC's DNS server resolution for $domain:\n" | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' \
                                                                       >> "$logFile"
    cmd.exe /c nslookup "$channelsHost.$domain" | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' \
                                                | sed '/Name/{n;s/^Address:  100\..*/Address:  100.[Redacted]/;}' \
                                                2>&1 >> "$logFile"

    echo -e "----------------------------------------" >> $logFile
  done

  echo -e "\nYour Windows PC's network interfaces:\n" >> "$logFile"
  cmd.exe /c ipconfig /all | sed 's/tail.*\.ts\.net/tail[Redacted].ts.net/' \
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
  cmd.exe /c tailscale version >> "$logFile"

  echo -e "\n----------------------------------------" >> $logFile

  cd - > /dev/null
}

main() {
  stackHealthcheck
  wslHealthcheck
  cat $logFile
  rm /tmp/tmp.*
}

main
