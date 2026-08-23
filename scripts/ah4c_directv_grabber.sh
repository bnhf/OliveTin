#!/bin/bash
# ah4c_directv_grabber.sh
# 2026.08.22

script=$(basename "$0" | sed 's/\.sh$//')
scriptDir=$(dirname "$0")
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

allchannelsGuideJSON=$(cat)
deepLinks="$1"

# Fallback station ids for callSigns whose own capture has no real Gracenote
# mapping (see stationId below), harvested from other captures over time.
# Shared with adbtuner_directv_grabber.sh - lives alongside the script (not
# /config) so it is tracked in this repo; in the container the script itself
# runs from /config, so scriptDir resolves there automatically at runtime.
# sdCallSignPairs is for the rarer case where an HD/SD pair does not even
# resolve as a pair automatically (neither nameBase nor csBase matches, e.g.
# "American Heroes HD" callSign AHCHD vs "American Heroes Channel" callSign
# AHCH) - a manually confirmed SD callSign -> HD callSign mapping.
stationIdOverridesFile="$scriptDir/directv_grabber_stationids.json"
stationIdOverrides='{}'
sdCallSignPairs='{}'
if [ -f "$stationIdOverridesFile" ]; then
  stationIdOverrides=$(jq -c '.overrides // {}' "$stationIdOverridesFile" 2>/dev/null || echo '{}')
  sdCallSignPairs=$(jq -c '.sdCallSignPairs // {}' "$stationIdOverridesFile" 2>/dev/null || echo '{}')
fi

generateM3U() {
  printf '%s\n' "$allchannelsGuideJSON" \
  | jq -r --arg deepLinks "${deepLinks:-true}" --argjson stationIdOverrides "$stationIdOverrides" --argjson sdCallSignPairs "$sdCallSignPairs" '
    # channelName is left untouched throughout - "HD"/"SD" stay in the
    # displayed name. Pairing an HD entry with its SD counterpart uses two
    # signals: the channelName with "HD" stripped (nameBase) and the
    # callSign with a trailing "HD" stripped (csBase). nameBase is checked
    # first and, when it finds a match, is used exclusively - callSign alone
    # is not reliable enough, since two different shows can share one raw
    # callSign (e.g. "Angels Broadcast Television" and "...Extra" are both
    # callSign "ABTV", only the channelName tells them apart). csBase is
    # only consulted as a fallback when no entry shares a nameBase, which is
    # the common case for local affiliates whose HD/SD names diverge (e.g.
    # "... A3 HD" vs "... SD") but whose callSign does not (e.g. "KTLA").
    def isHD: (.channelName | test("(?i)\\bHD\\b")) or (.callSign | test("(?i)HD$"));
    def nameBase: (.channelName | gsub("(?i)\\bHD\\b"; "") | gsub(" +"; " ") | sub("^ +"; "") | sub(" +$"; "") | ascii_downcase);
    def csBase: (.callSign | if test("(?i)HD$") then .[0:-2] else . end | ascii_downcase);
    # DirecTV often has not back-filled a real Gracenote/TMS mapping onto the
    # HD row of a pair - externalListingId just echoes the row own ccid
    # instead. Treat that as "no real id".
    def isFakeId: (.externalListingId == .ccid);
    # Within a duplicate channelNumber group, drop a non-HD entry only when
    # an HD entry in the same group is its counterpart. Anything left over
    # (true alternates, e.g. "ION East" vs "WNBA on ION 1/2/3", or distinct
    # feeds like "TNT HD" vs "TNT West HD") falls through unchanged to the
    # suffix logic below. When the surviving HD entry has no real station
    # id, prefer a previously-harvested id for its own callSign (see
    # stationIdOverridesFile) over borrowing from its SD counterpart in this
    # same capture - the override is a known-good id, whereas the SD
    # counterpart id is merely "not obviously fake" and could itself be
    # stale or wrong.
    def collapseHDPairs:
      . as $g
      | ($g | map(select(isHD | not))) as $sdEntries
      | ($g | map(select(isHD))) as $hdEntries
      | $g | map(
          . as $item
          | if (isHD | not) then
              ($item | nameBase) as $n
              | ($item | csBase) as $c
              | ($sdCallSignPairs[$item.callSign]) as $mappedHdCallSign
              | if ($hdEntries | map(select(nameBase == $n)) | length) > 0 then empty
                elif ($hdEntries | map(select(csBase == $c)) | length) > 0 then empty
                elif ($mappedHdCallSign != null) and ($hdEntries | map(select(.callSign == $mappedHdCallSign)) | length) > 0 then empty
                else $item
                end
            else
              ($item | nameBase) as $n
              | ($item | csBase) as $c
              | ($sdEntries | map(select(nameBase == $n))) as $byName
              | ($sdEntries | map(select(csBase == $c))) as $byCs
              | ($sdEntries | map(select(($sdCallSignPairs[.callSign]) == $item.callSign))) as $byManual
              | (if ($byName | length) > 0 then $byName
                 elif ($byCs | length) > 0 then $byCs
                 else $byManual
                 end) as $counterparts
              | if ($item | isFakeId) then
                  ($stationIdOverrides[$item.callSign]) as $overrideId
                  | if ($overrideId != null) then ($item | .externalListingId = $overrideId)
                    else
                      ($counterparts | map(select(isFakeId | not)) | .[0]) as $goodSd
                      | if $goodSd then ($item | .externalListingId = $goodSd.externalListingId) else $item end
                    end
                else $item
                end
            end
        );
    def isAlt: (.channelName | test("(?i)\\bAlternate\\b"));
    def isNumberedAlt: ((isAlt | not) and (.channelName | test("[0-9]+\\s*$")));
    def altNum: (.channelName | capture("(?<n>[0-9]+)\\s*$").n);
    # For a duplicate channelNumber group left over after HD/SD collapsing:
    # the one entry that is neither "Alternate" nor ends in a number is the
    # main channel and keeps the bare number. Entries named "... Alternate"
    # get sequential .1/.2 suffixes; entries named "... N" (e.g. "WNBA on
    # ION 1") get a suffix matching their own trailing number instead of
    # their position in the source data. If every entry in the group is
    # itself numbered and none stands out as a plain main (e.g. "ESPN+ 1"
    # through "ESPN+ 7", with no bare "ESPN+"), treat the lowest-numbered
    # entry as the implicit main so the rest still line up with their own
    # number. Anything else that does not resolve to exactly one main
    # channel falls back to the original order-based suffixing so nothing
    # is silently mishandled.
    def suffixGroup:
      . as $g
      | ($g | map(select((isAlt | not) and (isNumberedAlt | not)))) as $mains
      | if ($mains | length) == 1 then
          $mains[0] as $main
          | ($g | map(select(. != $main))) as $alts
          | ($alts | map(select(isAlt))) as $explicitAlts
          | ($alts | map(select(isNumberedAlt))) as $numberedAlts
          | [$main]
            + ($explicitAlts | to_entries | map(.value | .channelNumber = ($main.channelNumber + "." + ((.key + 1) | tostring))))
            + ($numberedAlts | map(.channelNumber = ($main.channelNumber + "." + altNum)))
        elif (($mains | length) == 0) and (($g | map(select(isNumberedAlt)) | length) == ($g | length)) then
          ($g | map(. + {_n: (altNum | tonumber)}) | sort_by(._n)) as $sorted
          | ($sorted[0] | del(._n)) as $main
          | ($sorted[1:] | map(del(._n) | .channelNumber = ($main.channelNumber + "." + altNum))) as $rest
          | [$main] + $rest
        else
          $g | to_entries | map(
            if .key == 0 then .value
            else .key as $k | .value | .channelNumber = (.channelNumber + "." + ($k | tostring))
            end
          )
        end;
    # A station id under 5 digits is not a real Gracenote/TMS mapping (see
    # collapseHDPairs). Fall back to a previously-harvested id for this
    # callSign (see stationIdOverridesFile) before giving up and showing "".
    def stationId:
      (.externalListingId // "" | if test("^[0-9]{5,}$") then . else "" end) as $own
      | if $own != "" then $own else ($stationIdOverrides[.callSign] // "") end;
    "#EXTM3U",
    "",
    (
      (.channelInfoList
       | group_by(.channelNumber | tonumber)
       | map(collapseHDPairs)
       | map(
           if length == 1 then .[0]
           else suffixGroup
           end
         )
       | flatten
      )[]
      | "#EXTINF:-1 channel-id=\"\(.channelNumber)\" channel-number=\"\(.channelNumber)\" tvc-guide-stationid=\"\(stationId)\",\(.channelName)",
        "http://{{ .IPADDRESS }}/play/tuner/\(if $deepLinks == "false" then .channelNumber else "\(.callSign)~\(.resourceId)" end)",
        ""
    )
  '
}

main() {
  generateM3U
}

main
