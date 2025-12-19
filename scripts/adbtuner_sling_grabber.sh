#!/bin/bash
# adbtuner_sling_grabber.sh
# 2025.12.15

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr="$1"
adbtunerSource="$2:$3"
customConfig="$(cat $4)"
  rm "$4"
customConfigUUID=$(printf '%s' "$customConfig" | jq -r '.uuid')
  [[ -z $customConfigUUID ]] && customConfigUUID="$5"
[[ "$6" == "false" ]] && slingRemove="" || slingRemove="$6"
[[ "$7" == "#" ]] && adbtStartingChannel="" || adbtStartingChannel="$7"
[[ -n $adbtStartingChannel ]] && adbtIgnoreM3UNumbers="ignore" || adbtIgnoreM3UNumbers=""

allchannelsGuideJSON=$(cat)

deleteExistingSling() {
  curl -fsS "http://$adbtunerSource/api/v1/channels" -H 'accept: application/json' \
  | jq -r --arg p "Sling" '.[] | select(.provider_name == $p) | .id' \
  | while read -r adbtunerChannel; do
      [[ -z "$adbtunerChannel" ]] && continue
      slingChannel="http://$adbtunerSource/api/v1/channels/$adbtunerChannel"
      echo -e "\nDELETE $slingChannel"
      curl -sS -X DELETE "$slingChannel"
    done
}

extractSlingData() {
  jq '
    [
      .special_ribbons[]
      .tiles[]
      .actions.DETAIL_VIEW
      | {
          CallSign: .adobe.CallSign,
          ChannelName: .adobe.ChannelName,
          PackageName: .adobe.PackageName,
          ItemID: .analytics.item_id,
          StationID: ""
        }
    ]
  '
}

removeFreestream() {
  jq '[ .[] | select(.PackageName | contains("Freestream") | not) ]'
}

addStationIDs() {
  local db="/config/adbtuner_sling.json"

  jq -e 'type=="array"' "$db" >/dev/null \
    || { echo "ERROR: $db missing or not a JSON array" >&2; return 1; }

  jq --slurpfile db "$db" '
    def norm: (tostring | gsub("^\\s+|\\s+$"; ""));
    def key_of: ((.item_id // .ItemID // .ItemId // .itemId // "") | norm);
    def val_of: ((.StationID // .stationId // "") | norm);

    def dbmap:
      ($db[0] // [])
      | map({ key: key_of, value: val_of })
      | map(select(.key != "" and .value != ""))
      | from_entries;

    dbmap as $m
    | map(
        if (((.StationID // "") | norm) != "") then .
        else
          .StationID = ($m[((.ItemID // .item_id // .ItemId // .itemId // "") | norm)] // "")
        end
      )
  ' \
  | jq -c '.[]' \
  | while read -r ch; do
      if [[ -z "$(jq -r '(.StationID // "")' <<<"$ch")" ]]; then
        callSign=$(jq -r '(.CallSign // "")' <<<"$ch")
        if [[ -n "$callSign" ]]; then
          stationId=$(
            curl -s "http://$dvr/tms/stations/$callSign" |
            jq -r --arg cs "$callSign" '
              map(select(.callSign == $cs)) | .[0].stationId // ""
            ' 2>/dev/null
          )
          ch=$(jq --arg stationId "$stationId" '.StationID = $stationId' <<<"$ch")
        fi
      fi
      printf '%s\n' "$ch"
    done \
  | jq -s '.'
}

createSlingJSON() {
  jq --arg uuid "$customConfigUUID" '
    map({
      m3u_id: "",
      provider_name: "Sling",
      number: null,
      name: .ChannelName,
      package_name: "com.sling",
      alternate_package_name: "com.sling",
      url_or_identifier: ("https://watch.sling.com/1/channel/" + (.ItemID // .item_id // "") + "/watch"),
      configuration_uuid: ($uuid // ""),
      tvc_guide_stationid: (.StationID // ""),
      guide_offset_hours: "",
      data: null,
      id: 0
    })
  '
}

createSlingConfig() {
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
  httpReturnCode=$(curl -sS -o /tmp/sling_config_post_response.json -w '%{http_code}' \
    -X POST "${postURL}" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "{\"json_data\": ${customConfig}}")

  if [[ "${httpReturnCode}" =~ ^2 ]]; then
    echo "[INFO] Configuration created successfully (HTTP ${httpReturnCode})."
  else
    echo "[ERROR] Failed to create configuration (HTTP ${httpReturnCode}). Response:"
    cat /tmp/sling_config_post_response.json
    echo
    return 1
  fi
}

createSlingChannels() {
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

  echo "Created ADBTuner - Sling channels"
}

customChannels() {
cat <<EOF
{
  "name": "ADBTuner - Sling",
  "type": "MPEG-TS",
  "source": "URL",
  "url": "http://$adbtunerSource/channels.m3u8?provider=Sling",
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
  && curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/ADBTuner-Sling
}

main() {
  [[ $slingRemove ]] && deleteExistingSling && echo
  [[ "$customConfigUUID" == "custom" && -n "$customConfig" ]] && createSlingConfig
  echo "$allchannelsGuideJSON" \
    | extractSlingData \
    | removeFreestream \
    | addStationIDs \
    | createSlingJSON \
    | createSlingChannels
  cdvrCustomSource
}

main
