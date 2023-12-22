#/bin/bash

set -x

dvr=$(echo $1 | sed 's/:/-/')
stationID=$2
[ -f "/config/"$dvr"_channel_list_latest.csv" ] || /config/channels_to_csv.sh $1

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
    }' /config/"$dvr"_channel_list_latest.csv