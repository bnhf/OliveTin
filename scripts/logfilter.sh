#!/bin/bash

set -x

dvr=$1
numberLines=$2
filterResult=$(echo $3 | sed 's/[][\.*^$(){}?+|/]/\\&/g')

scriptRun() {
case "$filterResult" in
  none)
    curl http://$dvr/log?n=$numberLines \
    && exit 0
  ;;
  *grep)
    filterResult=$(echo $filterResult | sed 's|\\||g' | sed 's|file://||')
    filterResult=$(cat /config/$filterResult)
    filterResult=$(echo $filterResult | sed 's/[][\.*^$(){}?+|/]/\\&/g')
    curl http://$dvr/log?n=$numberLines | grep "$filterResult"
    runResult=$?
    [[ "$runResult" == "1" ]] && echo "No results found using filter of $filterResult" && exit 0
    [[ "$runResult" == "0" ]] && exit 0
  ;;
  *)
    curl http://$dvr/log?n=$numberLines | grep "$filterResult"
    runResult=$?
    [[ "$runResult" == "1" ]] && echo "No results found using filter of $filterResult" && exit 0
    [[ "$runResult" == "0" ]] && exit 0
  ;;
esac
}

scriptRun
