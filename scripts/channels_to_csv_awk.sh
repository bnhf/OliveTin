#/bin/bash

stationID=$1
[ -f "/config/channels_dvr_channel_list_latest.csv" ] || /config/channels_to_csv.sh

awk -F',' -v pattern="$stationID" '
    NR == 1 {
        header = $0
    }
    tolower($0) ~ tolower(pattern) {
        data = $0
        split(header, headers, ",")
        split(data, values, ",")
        for (i = 1; i <= NF; i++) {
            printf "%s: %s\n", headers[i], values[i]
        }
        exit
    }'  /config/channels_dvr_channel_list_latest.csv
