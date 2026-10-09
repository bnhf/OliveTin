#!/bin/bash
# adbtuner_yttv_grabber.sh
# 2026.10.08

script=$(basename "$0" | sed 's/\.sh$//')
scriptDir=$(dirname "$0")
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr="$1"
adbtunerSource="$2:$3"
customConfig="$(cat $4)"
  rm "$4"
customConfigUUID=$(printf '%s' "$customConfig" | jq -r '.uuid // empty' 2>/dev/null)
[[ "$5" == "false" ]] && yttvRemove="" || yttvRemove="$5"
[[ "$6" == "#" ]] && adbtStartingChannel="" || adbtStartingChannel="$6"
[[ -n $adbtStartingChannel ]] && adbtIgnoreM3UNumbers="ignore" || adbtIgnoreM3UNumbers=""

# A browser "Copy as cURL" usually carries an accept-encoding header, so the
# guide response may arrive gzipped even with --compressed missing - inflate
# it here if so.
allchannelsGuideJSON=$(
  tmpGuide=$(mktemp)
  cat > "$tmpGuide"
  if [[ "$(head -c 2 "$tmpGuide" | od -An -tx1 | tr -d ' \n')" == "1f8b" ]]; then
    gunzip -c "$tmpGuide"
  else
    cat "$tmpGuide"
  fi
  rm -f "$tmpGuide"
)

# Gracenote station ids for YTTV channels - the guide response has none of
# its own. Lives alongside the script (not /config) so it is tracked in this
# repo; in the container the script itself runs from /config, so scriptDir
# resolves there automatically at runtime. See _description in the file.
stationIdsFile="$scriptDir/adbtuner_yttv_grabber_stationids.json"
yttvStations='[]'
if [ -f "$stationIdsFile" ]; then
  yttvStations=$(jq -c '.stations // []' "$stationIdsFile" 2>/dev/null || echo '[]')
else
  echo "[WARN] $stationIdsFile not found - channels will be created without guide station ids."
fi

deleteExistingYTTV() {
  curl -fsS "http://$adbtunerSource/api/v1/channels" -H 'accept: application/json' \
  | jq -r --arg p "YTTV" '.[] | select(.provider_name == $p) | .id' \
  | while read -r adbtunerChannel; do
      [[ -z "$adbtunerChannel" ]] && continue
      yttvChannel="http://$adbtunerSource/api/v1/channels/$adbtunerChannel"
      echo -e "\nDELETE $yttvChannel"
      curl -sS -X DELETE "$yttvChannel"
    done
}

createYTTVJSON() {
  adbtunerYTTVJSON=$(
    printf '%s\n' "$allchannelsGuideJSON" \
    | jq --arg uuid "$customConfigUUID" --argjson yttvStations "$yttvStations" '
      # Each guide row (epgRowRenderer) is one channel. The tuning id is the
      # videoId on the row itself (navigationEndpoint.watchEndpoint), not the
      # ones on its individual airings. Rows with nothing airing at capture
      # time (event-only and 4K feeds, mostly) carry no row-level
      # navigationEndpoint at all, so they cannot be tuned and are dropped.
      # The station display name is not always in .name, so fall back to the
      # icon accessibility label, then the callSign.
      def runsText: ((.runs // []) | map(.text) | join(""));
      def stationName:
        .station.epgStationRenderer as $s
        | [($s.name | runsText? // ""),
           ($s.icon.accessibility.accessibilityData.label // ""),
           ($s.callSign | runsText? // "")]
        | map(select(. != ""))
        | .[0] // "";
      # Gracenote id lookup: the YTTV stationId on the row is tried first,
      # and an entry found that way wins even when its stationId is empty
      # (an empty id deliberately suppresses a match). Only when the row
      # stationId is unknown does the display name get a try - and never for
      # local broadcast stations, whose names repeat across markets.
      ($yttvStations | map({key: .yttvStationId, value: .stationId}) | from_entries) as $byYttvId
      | ($yttvStations | map(select((.local | not) and .stationId != "")) | map({key: .name, value: .stationId}) | from_entries) as $byName
      | def gracenoteId:
          .yttvStationId as $id
          | if $byYttvId | has($id) then $byYttvId[$id]
            else $byName[.name] // ""
            end;
      [ .. | objects | .epgRowRenderer? // empty
        | { name: stationName, yttvStationId: (.stationId // ""), videoId: (.navigationEndpoint.watchEndpoint.videoId // "") }
        | select(.videoId != "" and .name != "")
        | .stationId = gracenoteId
      ]
      # Keep the first row for any repeated videoId, preserving guide order.
      | reduce .[] as $row ({seen: {}, out: []};
          if .seen[$row.videoId] then .
          else .seen[$row.videoId] = true | .out += [$row]
          end)
      | .out
      | map({
          m3u_id: "",
          provider_name: "YTTV",
          number: null,
          name: .name,
          package_name: "com.amazon.firetv.youtube.tv",
          alternate_package_name: "com.amazon.firetv.youtube.tv",
          url_or_identifier: ("https://tv.youtube.com/watch/" + .videoId),
          configuration_uuid: ($uuid // ""),
          tvc_guide_stationid: .stationId,
          guide_offset_hours: "",
          data: null,
          id: 0
        })
    '
  )

  local channelCount
  channelCount=$(printf '%s' "$adbtunerYTTVJSON" | jq 'length' 2>/dev/null)
  if [[ -z $channelCount || $channelCount -eq 0 ]]; then
    echo "[ERROR] No tunable YTTV channels found in the guide response. Check that the curl command was copied from the YouTube TV Live guide and has not expired."
    return 1
  fi
  echo "[INFO] Found $channelCount tunable YTTV channels, $(printf '%s' "$adbtunerYTTVJSON" | jq '[.[] | select(.tvc_guide_stationid != "")] | length') with guide station ids."
}

createYTTVConfig() {
  local getURL="http://${adbtunerSource}/api/v1/configurations"
  local postURL="http://${adbtunerSource}/api/v1/configuration"

  echo "[INFO] Checking for configuration ${customConfigUUID} at ${getURL}"

  local allConfigs
  if ! allConfigs=$(curl -sS -X GET "${getURL}" -H 'accept: application/json'); then
    echo "[ERROR] Failed to fetch configurations from ${getURL}"
    return 1
  fi

  if echo "${allConfigs}" | jq -e --arg uuid "${customConfigUUID}" '
      (map(select(
        (.uuid == $uuid) or
        (.json_data.uuid == $uuid)
      )) | length) > 0
    ' >/dev/null 2>&1; then
    echo "[INFO] Configuration ${customConfigUUID} already exists. Nothing to do."
    return 0
  fi

  echo "[INFO] Configuration ${customConfigUUID} not found. Creating it via POST ${postURL} ..."

  local httpReturnCode
  httpReturnCode=$(curl -sS -o /tmp/yttv_config_post_response.json -w '%{http_code}' \
    -X POST "${postURL}" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "{\"json_data\": ${customConfig}}")

  if [[ "${httpReturnCode}" =~ ^2 ]]; then
    echo "[INFO] Configuration created successfully (HTTP ${httpReturnCode})."
  else
    echo "[ERROR] Failed to create configuration (HTTP ${httpReturnCode}). Response:"
    cat /tmp/yttv_config_post_response.json
    echo
    return 1
  fi
}

createYTTVChannels() {
  jq -c '.[]' \
  | while IFS= read -r channelJSON; do
      curl -fsS \
        -X POST "http://${adbtunerSource}/api/v1/channels" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "$channelJSON" \
      || {
        echo "POST FAILED for channel: $channelJSON" >&2
        return 1
      }
    done

  echo "Created ADBTuner - YTTV channels"
}

customChannels() {
cat <<EOF
{
  "name": "ADBTuner - YTTV",
  "type": "MPEG-TS",
  "source": "URL",
  "url": "http://$adbtunerSource/channels.m3u8?provider=YTTV",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$adbtIgnoreM3UNumbers",
  "start_number": "$adbtStartingChannel",
  "logos": "",
  "xmltv_url": "",
  "xmltv_refresh": "3600"
}
EOF
}

cdvrCustomSource() {
  customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')

  echo -e "\nJSON response from $dvr:" \
  && curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/ADBTuner-YTTV
}

main() {
  createYTTVJSON || exit 1
  [[ $yttvRemove ]] && deleteExistingYTTV && echo
  [[ $customConfigUUID ]] && createYTTVConfig
  echo "$adbtunerYTTVJSON" | createYTTVChannels
  cdvrCustomSource
}

main
