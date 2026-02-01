#!/bin/bash
# stationid.sh
# 2026.01.16

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
stationName=$(echo "$2" | sed 's/ /%20/g; s/^/%22/; s/$/%22/')

curl -s "http://$dvr/tms/stations/$stationName" \
  | jq --raw-output '
    sort_by(.type, .name) | .[] |
    "type: \(.type), name: \(.name), callSign: \(.callSign), stationId: \(.stationId), affiliate: \(.affiliateCallSign)\n  logo: \(.preferredImage.uri)\n"
  '
