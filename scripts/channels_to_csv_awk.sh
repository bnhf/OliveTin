#!/bin/bash
# channels_to_csv_awk.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
stationID=$2
[ -f "/config/"$channelsHost"-"$channelsPort"_channel_list_latest.csv" ] || /config/channels_to_csv.sh $dvr

gawk -F',' -v pattern="$stationID" '
    NR == 1 {
        header = $0
    }
    function remove_spaces(s) {
        gsub(" ", "", s)
        return s
    }
    {
        data = $0
        split(header, headers, ",")
        split(data, values, ",")
        for (i = 1; i <= length(headers); i++) {
            if (tolower(remove_spaces(values[i])) ~ tolower(gensub(" ", ".*", "g", pattern))) {
                printf "Matched - Station ID: %s\n", values[i]
                for (j = 1; j <= length(headers); j++) {
                    printf "%s: %s\n", headers[j], values[j]
                }
                print "-------------------"  # Separator between matches
            }
        }
    }' /config/"$channelsHost"-"$channelsPort"_channel_list_latest.csv
