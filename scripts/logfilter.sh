#!/bin/bash
# logfilter.sh
# 2026.01.06

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
numberLines=$2
#filterResult=$(echo $3 | sed 's/[][\.*^$(){}?+|/]/\\&/g')
filterResult=$(echo $3 | sed 's/[][\^$(){}?+|/]/\\&/g')

scriptRun() {
case "$filterResult" in
  none)
    curl -s http://$dvr/log?n=$numberLines \
    && exit 0
  ;;
  *grep)
    filterResult=$(echo $filterResult | sed 's|\\||g' | sed 's|file://||')
    filterResult=$(cat /config/$filterResult)
    #filterResult=$(echo $filterResult | sed 's/[][\.*^$(){}?+|/]/\\&/g')
    filterResult=$(echo $filterResult | sed 's/[][\^$(){}?+|/]/\\&/g')
    curl -s http://$dvr/log?n=$numberLines | grep "$filterResult"
    runResult=$?
    [[ "$runResult" == "1" ]] && echo "No results found using filter of $filterResult" && exit 0
    [[ "$runResult" == "0" ]] && exit 0
  ;;
  *)
    curl -s http://$dvr/log?n=$numberLines | grep "$filterResult"
    runResult=$?
    [[ "$runResult" == "1" ]] && echo "No results found using filter of $filterResult" && exit 0
    [[ "$runResult" == "0" ]] && exit 0
  ;;
esac
}

scriptRun
