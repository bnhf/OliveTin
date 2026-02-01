#!/bin/bash
# prismcastconverter.sh
# 2026.01.29

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

prismcastHostPort="$1"
cc4cM3U="$2"

m3uToJson() {
    m3uText="${1:-}"

    echo "{"

    firstEntry=true

    while IFS= read -r m3uLine; do
        if [[ "$m3uLine" =~ ^#EXTINF:-1 ]]; then
            [[ "$m3uLine" =~ channel-id=\"([^\"]+)\" ]] && {
                local channelId="${BASH_REMATCH[1]}"
                local channelIdLower=$(echo "$channelId" | tr '[:upper:]' '[:lower:]')
            } || continue

            [[ "$m3uLine" =~ tvc-guide-stationid=\"([^\"]+)\" ]] && local stationId="${BASH_REMATCH[1]}" || local stationId=""

            [[ "$m3uLine" =~ ,(.+)$ ]] && local channelName="${BASH_REMATCH[1]}" || local channelName=""

            read -r urlLine

            [[ "$urlLine" =~ url=(.+)$ ]] && local channelUrl="${BASH_REMATCH[1]}" || local channelUrl="$urlLine"

            [[ "$firstEntry" == true ]] && firstEntry=false || echo ","

            echo -n "  \"$channelIdLower\": {"
            echo -n "\"name\": \"$channelName\", "
            echo -n "\"url\": \"$channelUrl\", "
            echo -n "\"stationId\": \"$stationId\""
            echo -n "}"
        fi
    done <<< "$m3uText"

    echo ""
    echo "}"
}

jsonToM3u() {
    jsonContent=$(cat)

    echo "#EXTM3U"
    echo ""

    jq -r 'to_entries[] |
        "\(.key)|\(.value.name)|\(.value.stationId)"' <<< "$jsonContent" | \
    while IFS='|' read -r channelId channelName stationId; do
        local channelIdUpper=$(echo "$channelId" | tr '[:lower:]' '[:upper:]')

        echo "#EXTINF:-1 channel-id=\"$channelIdUpper\" tvc-guide-stationid=\"$stationId\",$channelName"

        echo "http://${prismcastHostPort}/hls/${channelId}/stream.m3u8"
        echo ""
    done
}

main() {
    greenEcho "JSON response from $prismcastHostPort:"
    m3uToJson "$cc4cM3U" | curl -s -X POST -H "Content-Type: application/json" -d @- http://$prismcastHostPort/config/channels/import
    echo
    echo
    greenEcho "Copy and paste the following M3U into your PrismCast CDVR Custom Channels Source"
    greenEcho "as a text-based M3U source:"
    echo
    curl -s http://$prismcastHostPort/config/channels/export | jsonToM3u
}

main
