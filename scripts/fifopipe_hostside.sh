#!/bin/bash

echo -e "\nThis script will be terminated from the container side once the OliveTin healthcheck has finished running..."

fifoPipe="./fifopipe"

[ ! -p "$fifoPipe" ] && mkfifo "$fifoPipe"

finish() {
  rm $fifoPipe
}

trap finish EXIT

while true; do
  if read -r hostCommand < "$fifoPipe"; then
    case "$hostCommand" in
      "tailscale netcheck")
        tailscale netcheck > "$fifoPipe"_latest.log 2>&1
        ;;
      "tailscale status")
        tailscale status > "$fifoPipe"_latest.log 2>&1
        ;;
      "WSL_DISTRO_NAME")
        echo "$WSL_DISTRO_NAME" > "$fifoPipe"_latest.log 2>&1
        ;;
      "LINUX_DISTRO_NAME")
        cat /etc/os-release > "$fifoPipe"_latest.log 2>&1
        ;;      
      "resolv.conf")
        cat /etc/resolv.conf > "$fifoPipe"_latest.log 2>&1
        ;;
      "hosts")
        cat /etc/hosts > "$fifoPipe"_latest.log 2>&1
        ;;
      "wsl.conf")
        cat /etc/wsl.conf > "$fifoPipe"_latest.log 2>&1
        ;;
      ".wslconfig")
        cat /mnt/c/Users/$(whoami)/.wslconfig > "$fifoPipe"_latest.log 2>&1
        ;;
      "windows_hosts")
        cat /mnt/c/Windows/System32/drivers/etc/hosts > "$fifoPipe"_latest.log 2>&1
        ;;
      nslookup*)
        cmd.exe /c $hostCommand > "$fifoPipe"_latest.log 2>&1
        ;;
      "windows_ipconfig")
        cmd.exe /c ipconfig /all > "$fifoPipe"_latest.log 2>&1
        ;;
      "END_OF_RUN")
        exit 0
        ;;
      *)
        echo "Unrecognized command: $hostCommand" > "$fifoPipe"_latest.log
        ;;
    esac
  else
    echo "Error reading from FIFO pipe" > "$fifoPipe"_latest.log
  fi
  sleep 1
done
