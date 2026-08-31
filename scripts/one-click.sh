#!/bin/bash
# one-click.sh
# 2026.08.29
# Shared helpers for the OliveTin One-Click scripts that call portainerstack.sh. Source near the top: source /config/one-click.sh
# It's sourced, so $0 is the calling script -- this file sets up that script's debug log, helpers, /tmp paths, and exit-banner trap.

# the calling script inherits all of this: $extension, its debug log, xtrace, and the /tmp env/dirs paths
extension=${0##*/}; extension=${extension%.sh}
exec 3> "/config/$extension.debug.log"
BASH_XTRACEFD=3
set -x
envFile="/tmp/$extension.env"
dirsFile="/tmp/$extension.dirs"

# small helpers, used inline throughout (and by callers)
greenEcho()   { echo -e "\033[0;32m$1\033[0m ${*:2}"; }
redEcho()     { echo -e "\033[0;31m$1\033[0m ${*:2}"; }
blueSpinner() { local t=$1 i=0 s='|/-\'; while (( i < t*5 )); do printf "\r\033[34m%c\033[0m" "${s:i++%4:1}"; sleep 0.2; done; printf "\r \r"; }
emptyIfHash() { [[ "$1" == "#" ]] || printf '%s' "$1"; }

# label every exit path -- red on non-zero, green on zero
trap '(( $? )) && redEcho "\nFinished -- with errors" || greenEcho "\nFinished -- no errors registered"' EXIT

# one-clickPreflight <hostPortArg> [label] -- set extensionURL; exit 1 if PORTAINER_HOST unset, exit 0 if the port already answers
one-clickPreflight() {
  [[ -n $PORTAINER_HOST ]] || { redEcho "PORTAINER_HOST not set. Confirm you're using the latest OliveTin docker-compose"; exit 1; }
  extensionURL="$PORTAINER_HOST:$1"
  curl -s -o /dev/null "http://$extensionURL" && {
    greenEcho "\n$extensionURL is already in use by another ${2:-$extension} container or some other application."
    exit 0
  }
}

# one-clickCdvrNumbering <startChanArg> -- set cdvrStartingChannel ("#" = unset); a real value also sets cdvrIgnoreM3UNumbers=ignore
one-clickCdvrNumbering() {
  cdvrStartingChannel=$(emptyIfHash "$1")
  [[ -n $cdvrStartingChannel ]] && cdvrIgnoreM3UNumbers=ignore
}

# one-clickCreateStack [extra portainerstack.sh args] -- write envVars[] (+ synologyDirs[] if set) to /tmp, strip KEY=# lines, run portainerstack.sh; exit 1 on failure
one-clickCreateStack() {
  cp "/config/$extension.env" /tmp
  printf "%s\n" "${envVars[@]}" > "$envFile"
  [[ ${synologyDirs+x} ]] && printf "%s\n" "${synologyDirs[@]}" > "$dirsFile"
  sed -i '/=#/d' "$envFile"
  /config/portainerstack.sh "$extension" "$@" || exit 1
}

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60, 0=forever] -- poll until it answers; exit 1 when tries run out
one-clickWaitForUp() {
  local url="${1:-http://$extensionURL}" label="${2:-$extension}" max="${3:-60}" n=0
  greenEcho "\nWaiting for $label ($url) to respond..."
  until curl -s -o /dev/null "$url"; do
    (( max && ++n >= max )) && { redEcho "\n$label ($url) did not respond after $max attempts -- check the stack's logs in Portainer."; exit 1; }
    blueSpinner 5
  done
}

# one-clickVerifyM3U <url> [hint line]... -- poll ~10x for an #EXTM3U body; on failure print a generic warning + any hints, then exit 1
one-clickVerifyM3U() {
  local url="$1"; shift
  greenEcho "\nVerifying M3U is readable at $url..."
  for _ in {1..10}; do
    [[ "$(curl -s "$url" | head -c7)" == "#EXTM3U" ]] && { greenEcho "M3U verified."; return; }
    blueSpinner 3
  done
  redEcho "\nERROR: $url did not return a valid M3U (missing #EXTM3U header)."
  echo "Skipping CDVR Custom Channel Source registration."
  echo "The $extension stack was created in Portainer above -- re-running this action as-is will fail there with a name conflict."
  echo "Stop and delete that stack in Portainer before re-running (or fix the cause in place if the M3U is served from a file you control)."
  (( $# )) && printf '%s\n' "$@"
  exit 1
}

# one-clickChannelJson name=.. url=.. [type=HLS] [source=URL] [text=..] [limit=..] [xmltv=..] [start=..] [numbering=..] [refresh=24]
#   start=/numbering= default to the one-clickCdvrNumbering globals; refresh= defaults to 24. Pass any of them (incl. empty) to override.
one-clickChannelJson() {
  local name type=HLS source=URL url text limit xmltv start numbering refresh keyValue
  for keyValue in "$@"; do case $keyValue in
    name=*)      name=${keyValue#*=} ;;
    type=*)      type=${keyValue#*=} ;;
    source=*)    source=${keyValue#*=} ;;
    url=*)       url=${keyValue#*=} ;;
    text=*)      text=${keyValue#*=} ;;
    limit=*)     limit=${keyValue#*=} ;;
    xmltv=*)     xmltv=${keyValue#*=} ;;
    start=*)     start=${keyValue#*=} ;;
    numbering=*) numbering=${keyValue#*=} ;;
    refresh=*)   refresh=${keyValue#*=} ;;
  esac; done
  cat <<EOF
{
  "name": "$name",
  "type": "$type",
  "source": "$source",
  "url": "$url",
  "text": "$text",
  "refresh": "${refresh-24}",
  "limit": "$limit",
  "satip": "",
  "numbering": "${numbering-$cdvrIgnoreM3UNumbers}",
  "start_number": "${start-$cdvrStartingChannel}",
  "logos": "",
  "xmltv_url": "$xmltv",
  "xmltv_refresh": "3600"
}
EOF
}

# one-clickRegisterSource <slug> <json> -- flatten <json> and PUT to $dvr as a Custom Channel Source; exit 1 on curl failure
one-clickRegisterSource() {
  greenEcho "\nJSON response from $dvr:"
  curl -s -X PUT -H "Content-Type: application/json" -d "$(printf '%s' "$2" | tr -d '\n')" "http://$dvr/providers/m3u/sources/$1" || exit 1
}
