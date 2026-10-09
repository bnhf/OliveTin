#!/bin/bash
# apituner_yttv_grabber.sh
# 2026.10.09

script=$(basename "$0" | sed 's/\.sh$//')
scriptDir=$(dirname "$0")
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

configurationUUID="$1"

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
# its own. Shared with adbtuner_yttv_grabber.sh - lives alongside the script
# (not /config) so it is tracked in this repo; in the container the script
# itself runs from /config, so scriptDir resolves there automatically at
# runtime. See _description in the file. A missing file is only warned about
# on stderr, so stdout stays pure JSON.
stationIdsFile="$scriptDir/youtubetv_grabber_stationids.json"
yttvStations='[]'
if [ -f "$stationIdsFile" ]; then
  yttvStations=$(jq -c '.stations // []' "$stationIdsFile" 2>/dev/null || echo '[]')
else
  echo "[WARN] $stationIdsFile not found - channels will be created without guide station ids." >&2
fi

generateJSON() {
  printf '%s\n' "$allchannelsGuideJSON" \
  | jq --arg configurationUUID "$configurationUUID" --argjson yttvStations "$yttvStations" '
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
    # YTTV has no channel numbers of its own, so number is left null.
    | map({
        provider_name: "YTTV",
        number: null,
        name: .name,
        url: ("https://tv.youtube.com/watch/" + .videoId),
        package_name: "com.amazon.firetv.youtube.tv",
        alternate_package_name: "com.amazon.firetv.youtube.tv",
        tvc_guide_stationid: .stationId,
        guide_offset_hours: "",
        configuration_uuid: $configurationUUID
      })
    # sort_order is a 1-based running index over the final channel list,
    # emitted as a one-decimal string ("1.0", "2.0", ...) to match the
    # native-app station-record format.
    | to_entries
    | map(.value + { sort_order: ((.key + 1 | tostring) + ".0") })
  '
}

main() {
  local channelsJSON
  channelsJSON=$(generateJSON)
  if [[ -z $channelsJSON || $(printf '%s' "$channelsJSON" | jq 'length' 2>/dev/null) == "0" ]]; then
    echo "[ERROR] No tunable YTTV channels found in the guide response. Check that the curl command was copied from the YouTube TV Live guide and has not expired."
    exit 1
  fi
  printf '%s\n' "$channelsJSON"
}

main
