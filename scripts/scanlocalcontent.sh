#!/bin/bash
# scanlocalcontent.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

dvr=$1
urlAction=$2

greenEcho "\nJSON response from $dvr:"
curl -s -X PUT http://$dvr/dvr/scanner/$urlAction
