#!/bin/bash
# espn4adbt.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

dvr="$1"
adbtunerSource="$2:$3"
espn4cc4cLanes="$4"
espn4cc4cSource="$5:$6"
curl -s -o /dev/null http://$adbtunerSource || { echo "ADBTuner not answering on http://$adbtunerSource"; exit 1; }
curl -s -o /dev/null http://$espn4cc4cSource || { echo "ESPN4cc4c not answering on http://$espn4cc4cSource"; exit 1; }
[[ "$7" == "false" ]] && espnRemove="" || espnRemove="$7"
[[ "$8" == "#" ]] && adbtStartingChannel="" || adbtStartingChannel="$8"
[[ -n $adbtStartingChannel ]] && adbtIgnoreM3UNumbers="ignore" || adbtIgnoreM3UNumbers=""

deleteExistingESPN() {
  curl -fsS "http://$adbtunerSource/api/v1/channels" -H 'accept: application/json' \
  | jq -r --arg p "ESPN" '.[] | select(.provider_name == $p) | .id' \
  | while read -r adbtunerChannel; do
      [[ -z "$adbtunerChannel" ]] && continue
      espnChannel="http://$adbtunerSource/api/v1/channels/$adbtunerChannel"
      echo -e "\nDELETE $espnChannel"
      curl -sS -X DELETE "$espnChannel"
    done
}

createESPNConfig() {
  local uuid="51af5028-092f-4ddc-b4ea-d5e5fca58cac"
  local get_url="http://${adbtunerSource}/api/v1/configurations"
  local post_url="http://${adbtunerSource}/api/v1/configuration"

  echo "[INFO] Checking for configuration ${uuid} at ${get_url}"

  local configs
  if ! configs=$(curl -sS -X GET "${get_url}" -H 'accept: application/json'); then
    echo "[ERROR] Failed to fetch configurations from ${get_url}"
    return 1
  fi

  if echo "${configs}" | jq -e --arg uuid "${uuid}" '
      (map(select(
        (.uuid == $uuid) or
        (.json_data.uuid == $uuid)
      )) | length) > 0
    ' >/dev/null 2>&1; then
    echo "[INFO] Configuration ${uuid} already exists. Nothing to do."
    return 0
  fi

  echo "[INFO] Configuration ${uuid} not found. Creating it via POST ${post_url} ..."

  local body
  body=$(cat <<'JSON'
{
  "json_data": {
    "name": "ESPN+ Deep Links - Show Tuning Process",
    "author": "bnhf",
    "version": "1.0",
    "description": "Load content via ESPN+ deep link URLs (where supported). Show tuning process.",
    "uuid": "51af5028-092f-4ddc-b4ea-d5e5fca58cac",
    "global_options": {
      "wait_for_video_playback_detection": false,
      "use_fixed_delay": true,
      "fixed_delay_seconds": 5,
      "check_for_and_clear_whos_watching_prompts": false,
      "wait_after_post_playback_start_commands_seconds": 0
    },
    "pre_tune_commands": [
      "input keyevent KEYCODE_MEDIA_STOP"
    ],
    "tune_commands": [
      "am start -n ||TARGET_PACKAGE_NAME||/com.espn.startup.presentation.StartupActivity -d ||TARGET_URL_OR_IDENTIFIER||"
    ],
    "post_playback_start_commands": [
      "sleep 20",
      "input keyevent KEYCODE_DPAD_DOWN",
      "input keyevent KEYCODE_DPAD_DOWN",
      "input keyevent KEYCODE_DPAD_RIGHT",
      "input keyevent KEYCODE_DPAD_CENTER"
    ],
    "post_tune_commands": [
      "input keyevent KEYCODE_MEDIA_STOP",
      "input keyevent KEYCODE_MEDIA_PAUSE",
      "input keyevent KEYCODE_HOME"
    ],
    "source_file": "/app/.config/user_configurations/51af5028-092f-4ddc-b4ea-d5e5fca58cac.json"
  },
  "uuid": "51af5028-092f-4ddc-b4ea-d5e5fca58cac"
}
JSON
)

  local http_code
  http_code=$(curl -sS -o /tmp/espn_config_post_response.json -w '%{http_code}' \
    -X POST "${post_url}" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "${body}")

  if [[ "${http_code}" =~ ^2 ]]; then
    echo "[INFO] Configuration created successfully (HTTP ${http_code})."
  else
    echo "[ERROR] Failed to create configuration (HTTP ${http_code}). Response:"
    cat /tmp/espn_config_post_response.json
    echo
    return 1
  fi
}

generateM3UID() {
  python3 - <<'EOF'
import uuid
print(uuid.uuid4().int)
EOF
}

createESPNLanes() {
  for ((espn4cc4cLane=1; espn4cc4cLane<=espn4cc4cLanes; espn4cc4cLane++)); do

    m3u_id="${espn4cc4cLane}"
    name="ESPN+${espn4cc4cLane}"
    url="http://$espn4cc4cSource/whatson/${espn4cc4cLane}?deeplink=1&dynamic_url_json_key=deeplink_url"

    jq -n \
      --arg m3u_id "$m3u_id" \
      --arg name "$name" \
      --arg url "$url" \
      --arg cfg "51af5028-092f-4ddc-b4ea-d5e5fca58cac" \
      '{
        m3u_id: $m3u_id,
        provider_name: "ESPN",
        number: null,
        name: $name,
        package_name: "com.espn.gtv",
        alternate_package_name: "com.espn.score_center",
        url_or_identifier: $url,
        configuration_uuid: $cfg,
        tvc_guide_stationid: "",
        guide_offset_hours: "",
        data: null,
        id: 0
      }' |
      curl -fsS "http://$adbtunerSource/api/v1/channels" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d @- \
      || { echo "POST failed for lane $espn4cc4cLane" >&2; return 1; }

    echo "Created channel: $name"
  done
}

customChannels() {
cat <<EOF
{
  "name": "ESPN4adbt",
  "type": "MPEG-TS",
  "source": "URL",
  "url": "http://$adbtunerSource/channels.m3u8?provider=ESPN",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$adbtIgnoreM3UNumbers",
  "start_number": "$adbtStartingChannel",
  "logos": "",
  "xmltv_url": "http://$espn4cc4cSource/out/epg.xml",
  "xmltv_refresh": "3600"
}
EOF
}

cdvrCustomSource() {
  customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')

  greenEcho "\nJSON response from $dvr:" \
  && curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/ESPN4adbt
}

main() {
  [[ $espnRemove ]] && deleteExistingESPN && echo
  createESPNConfig
  createESPNLanes
  cdvrCustomSource
}

main
