// ==UserScript==
// @name         OliveTin Dropdown for CDVR WebUI
// @namespace    local
// @version      2026.01.27.0753
// @description  Adds OliveTin dropdown to Channels UI; runs OliveTin actions with dynamic forms
// @author       bnhf
// @match        http*://*/admin/*
// @run-at       document-idle
//
// @require      https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/lib/xterm.min.js
// @require      https://cdn.jsdelivr.net/npm/@xterm/addon-fit@0.10.0/lib/addon-fit.min.js
// @resource     XTERM_CSS https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/css/xterm.min.css
//
// @grant        GM_xmlhttpRequest
// @grant        GM_getResourceText
// @grant        GM_addStyle
// @connect      ${PORTAINER_HOST}
// ==/UserScript==
/* eslint-disable no-multi-spaces */

(() => {
  "use strict";

  // ============================================================
  // CONFIG - Edit this section to add new OliveTin actions
  // ============================================================

  const OLIVETIN_BASE = "http://${PORTAINER_HOST}:1337";
  const DVR_VALUE = "${CHANNELS_DVR} ${CHANNELS_DVR_ALTERNATES}";

  // Parse DVR_VALUE into an array of servers (space-separated, filter empty strings)
  const DVR_SERVERS = DVR_VALUE.trim().split(/\s+/).filter(s => s.length > 0);
  const DVR_DEFAULT = DVR_SERVERS[0] || "";

  // Build DVR argument config - dropdown if multiple servers, simple input if single
  function getDvrArgument() {
    if (DVR_SERVERS.length > 1) {
      return {
        name: "dvr",
        label: "DVR Server",
        description: "Select Channels DVR server",
        default: DVR_DEFAULT,
        options: DVR_SERVERS.map(server => ({ display: server, value: server }))
      };
    }
    // Single server - still show it but as a pre-filled input
    return {
      name: "dvr",
      label: "DVR Server",
      description: "Channels DVR server address",
      default: DVR_DEFAULT
    };
  }

  // Define your OliveTin actions here
  // Each action creates a menu item and generates a modal with input fields
  // Actions are sorted alphabetically by label
  const ACTIONS = [
    {
      id: "adbpackages",
      label: "ADB Installed Packages List",
      title: "List Apps Installed on Connected ah4c ADB Devices",
      arguments: [
        { name: "container_name", label: "Container Name", default: "ah4c", description: "ah4c container name" },
      ],
    },
    {
      id: "adbtuneralerts",
      label: "ADBTuner Device Alerter",
      title: "ADBTuner Device Alerter",
      arguments: [
        getDvrArgument(),
        { name: "frequency", label: "Frequency", default: "30m", description: "Check interval (m for minutes, h for hours). 0 to kill background process" },
        { name: "adbtuner_host_port", label: "ADBTuner Host:Port", default: "htpc6:5592", description: "ADBTuner host:port or ip:port" },
        { name: "apprise_url", label: "Apprise URL", default: "none", description: "Apprise URL for notifications (none = use OliveTin ALERT_EMAIL)" },
      ],
    },
    {
      id: "adbalerts",
      label: "ah4c ADB Device Alerts",
      title: "E-Mail ah4c ADB Device Alerts",
      arguments: [
        getDvrArgument(),
        { name: "frequency", label: "Frequency", default: "30m", description: "Check interval (m for minutes, h for hours). 0 to kill background process" },
        { name: "container_name", label: "Container Name", default: "ah4c", description: "ah4c container name" },
      ],
    },
    {
      id: "channels_dvr_monitor_channels",
      label: "Channel Lineup Monitor",
      title: "Channel Lineup Change Notifications",
      arguments: [
        getDvrArgument(),
        { name: "frequency", label: "Frequency (min)", default: "30", description: "Query frequency in minutes (minimum 5). 0 to kill background process" },
        { name: "start", label: "Start Time", default: "none", description: "Future start time in HH:MM format (none = start now)" },
        { name: "email", label: "Sender Email", default: "none", description: "Email address for sender ($ALERT_EMAIL_FROM for env value)" },
        { name: "password", label: "Email Password", default: "none", description: "Email password ($ALERT_EMAIL_PASS for env value)" },
        { name: "recipient", label: "Recipient Email", default: "none", description: "Recipient email ($ALERT_EMAIL_TO for env value)" },
        { name: "text", label: "SMS Number", default: "none", description: "Cell number as 10digits@gateway (none for blank)" },
      ],
    },
    {
      id: "channels_to_csv",
      label: "Channels List CSV",
      title: "Create Channels List in CSV Format",
      arguments: [
        getDvrArgument(),
      ],
    },
    {
      id: "comskipignore",
      label: "Comskip Off/On by Channel",
      title: "Turn Comskip Off/On by Channel",
      arguments: [
        getDvrArgument(),
        { name: "channel", label: "Channel", placeholder: "Enter channel number" },
        {
          name: "action",
          label: "Action",
          description: "Turn Comskip On or Off for the above channel",
          placeholder: "Select action...",
          options: [
            { display: "Off", value: "PUT" },
            { display: "On", value: "DELETE" },
          ]
        },
      ],
    },
    {
      id: "comskipini",
      label: "Comskip Settings",
      title: "Update Comskip Settings Used by Channels DVR",
      arguments: [
        getDvrArgument(),
        { name: "mincombreakstartend", label: "Min Break Start/End", default: "default", description: "min_commercial_break_at_start_or_end (Comskip Default=39)" },
        { name: "alwayskeepfirstsecs", label: "Always Keep First Secs", default: "default", description: "always_keep_first_seconds (Comskip Default=0)" },
        { name: "alwayskeeplastsecs", label: "Always Keep Last Secs", default: "default", description: "always_keep_last_seconds (Comskip Default=0)" },
        { name: "minshowseglength", label: "Min Show Segment Length", default: "default", description: "min_show_segment_length (CDVR Default=222)" },
        { name: "mincommercialbreak", label: "Min Commercial Break", default: "default", description: "min_commercialbreak (CDVR Default=45)" },
        { name: "threadcount", label: "Thread Count", default: "default", description: "threadcount (CDVR Default=1)" },
      ],
    },
    {
      id: "create_collection_from_sources",
      label: "Create Collection from Sources",
      title: "Create a Channel Collection from One or More Sources",
      arguments: [
        getDvrArgument(),
        { name: "collection_name", label: "Collection Name", default: "My Collection", description: "Name for the Channel Collection" },
        { name: "sources", label: "Sources", default: '"Virtual Channels" "DIRECTV"', description: "Sources in quotes, space-separated" },
      ],
    },
    {
      id: "ccextractor",
      label: "Create Subtitles from CC",
      title: "Create Subtitles (.srt) File from Closed Captions",
      arguments: [
        getDvrArgument(),
        { name: "recording_path", label: "Recording Path", default: "Movies", description: "Path relative to mounted dvr path (e.g., TV/The Closer or Movies)" },
        { name: "recording_filename", label: "Recording Filename", placeholder: "Wild (2014) 2023-06-26-1900", description: "Filename without extension" },
      ],
    },
    {
      id: "backupdatabase",
      label: "Custom Backup CDVR Database",
      title: "Backup CDVR Server Database at a Custom Interval",
      arguments: [
        getDvrArgument(),
        { name: "interval", label: "Interval", default: "once", description: "Backup interval (m for minutes, h for hours). once for single run. 0 to kill background process" },
        { name: "healthchecks_io", label: "Healthchecks URL", default: "https://hc-ping.com/your_custom_uuid", description: "Optional healthchecks.io ping URL", optional: true },
      ],
    },
    {
      id: "deletelogs",
      label: "Delete CDVR Recording Log Files",
      title: "Delete Channels DVR Recording Log Files",
      arguments: [
        getDvrArgument(),
        { name: "interval", label: "Interval", default: "once", description: "Run/Age interval (d for days). E.g., 7d = run every 7 days deleting files > 7 days old. 0 to kill" },
        { name: "healthchecks_io", label: "Healthchecks URL", default: "https://hc-ping.com/your_custom_uuid", description: "Optional healthchecks.io ping URL", optional: true },
      ],
    },
    {
      id: "deletewatched",
      label: "Delete Watched Videos",
      title: "Delete Watched Videos",
      arguments: [
        getDvrArgument(),
        { name: "interval", label: "Interval", default: "once", description: "Check interval (m for minutes, h for hours). once for single run. 0 to kill" },
        { name: "healthchecks_io", label: "Healthchecks URL", default: "https://hc-ping.com/your_custom_uuid", description: "Optional healthchecks.io ping URL", optional: true },
      ],
    },
    {
      id: "logfilter",
      label: "Filter CDVR Logs",
      title: "Generate Filtered Channels DVR Log",
      arguments: [
        getDvrArgument(),
        { name: "lines", label: "Lines", default: "100", description: "Number of log lines to grab" },
        { name: "filter", label: "Filter", default: "none", description: "Grep filter (e.g., [ERR], Face the Nation). file://_.grep to load from file" },
      ],
    },
    {
      id: "fix_thumbnails",
      label: "Fix YouTube Thumbnails",
      title: "Fix YouTube Thumbnails",
      arguments: [
        getDvrArgument(),
        { name: "interval", label: "Interval", default: "once", description: "Run interval (m for minutes, h for hours). once for single run. 0 to kill" },
        { name: "healthchecks_io", label: "Healthchecks URL", default: "https://hc-ping.com/your_custom_uuid", description: "Optional healthchecks.io ping URL", optional: true },
      ],
    },
    {
      id: "generatem3u",
      label: "Generate Custom M3U Playlist",
      title: "Generate a Channels DVR M3U Playlist",
      arguments: [
        getDvrArgument(),
        { name: "source", label: "Source", default: "ANY", description: "ANY for all sources, or source name from settings" },
        { name: "collection", label: "Collection", default: "none", description: "Channel Collection name (none = all channels)" },
        { name: "bitrate", label: "Bitrate", default: "none", description: "none = default, x000 = Kbps, copy = remux only" },
        { name: "filter", label: "Filter", default: "none", description: "none, hd, favorites, or logos" },
        { name: "format", label: "Format", default: "hls", description: "hls or ts" },
        { name: "abr", label: "ABR", default: "true", description: "Adaptive Bitrate (true/false)" },
        { name: "duration", label: "Guide Duration", default: "none", description: "Guide data in seconds (604800 = 1 week)" },
      ],
    },
    {
      id: "stationid",
      label: "Gracenote Station IDs",
      title: "Find Gracenote Station IDs",
      arguments: [
        getDvrArgument(),
        { name: "station", label: "Station", placeholder: "HBO 2" },
      ],
    },
    {
      id: "listcomskipignore",
      label: "List Comskip Ignored Channels",
      title: "List Channels with Comskip Off",
      arguments: [
        getDvrArgument(),
      ],
    },
    {
      id: "logalerts",
      label: "Log Alerts",
      title: "E-Mail Custom Log Alerts",
      arguments: [
        getDvrArgument(),
        { name: "frequency", label: "Frequency", default: "2m", description: "Log check interval (m for minutes, h for hours). 0 to kill" },
        { name: "filter1", label: "Filter 1", default: "[DVR] Error", description: "First grep filter (none = not used)" },
        { name: "filter2", label: "Filter 2", default: "none", description: "Second grep filter" },
        { name: "filter3", label: "Filter 3", default: "none", description: "Third grep filter" },
        { name: "filter4", label: "Filter 4", default: "none", description: "Fourth grep filter" },
        { name: "filter5", label: "Filter 5", default: "none", description: "Fifth grep filter" },
        { name: "apprise_url", label: "Apprise URL", default: "olivetin://", description: "Apprise URL (olivetin:// = ALERT_EMAIL)" },
      ],
    },
    {
      id: "manualrecordings",
      label: "Manually Add Recordings",
      title: "Manually Add Recordings",
      arguments: [
        getDvrArgument(),
        { name: "name", label: "Name", placeholder: "Enter recording name", description: "The name you'd like used for the recording" },
        { name: "channel", label: "Channel", placeholder: "Enter channel number", description: "The channel number to use for the recording" },
        { name: "time", label: "Time", placeholder: "hh:mm or mm/dd/yyyy hh:mm", description: "Start time in 24h format, or with date" },
        { name: "duration", label: "Duration", placeholder: "Enter minutes", description: "The length of the recording in minutes" },
        { name: "summary", label: "Summary", default: "none", description: "A description of the recording (optional)", optional: true },
        { name: "genres", label: "Genres", default: "none", description: "Genre(s) - comma separated (optional)", optional: true },
        { name: "image", label: "Image URL", default: "https://tmsimg.fancybits.co/assets/p9467679_st_h6_aa.jpg", description: "An image URL to use for the recording", optional: true },
        {
          name: "type",
          label: "Type",
          description: "Recording type - choose TV Series or Movie",
          placeholder: "Select type...",
          options: [
            { display: "TV Series", value: "tv" },
            { display: "Movie", value: "movie" },
          ]
        },
      ],
    },
    {
      id: "markforrerecord",
      label: "Mark for Re-Recording",
      title: "Mark a Movie or Episode for Re-Recording",
      arguments: [
        getDvrArgument(),
        { name: "file_id", label: "File ID", placeholder: "Enter File ID", description: "Library - TV Shows/Movies - <name> - Options - View Details - File ID" },
      ],
    },
    {
      id: "cdvr_movie_library_to_csv",
      label: "Movies List CSV",
      title: "Create Movies List in CSV Format",
      arguments: [
        getDvrArgument(),
      ],
    },
    {
      id: "playonedl",
      label: "PlayOn EDL Creator from Chapters",
      title: "Create EDL File from PlayOn Recording Chapters",
      arguments: [
        getDvrArgument(),
        { name: "playon_path", label: "PlayOn Path", default: "Movies", description: "Path after dvr/PlayOn (e.g., TV/The Guardian)" },
        { name: "playon_mp4", label: "PlayOn MP4", placeholder: "The Guardian - S1E1 - Pilot.mp4", description: "MP4 filename or *.mp4 for all in path" },
      ],
    },
    {
      id: "remind",
      label: "Recording/Watch Reminders Onscreen",
      title: "Event Reminders for Upcoming Recordings",
      arguments: [
        getDvrArgument(),
        {
          name: "frequency",
          label: "Frequency",
          description: "Reminder check frequency in minutes. 0 to kill",
          default: "5",
          options: [
            { display: "0 (Stop)", value: "0" },
            { display: "5", value: "5" },
            { display: "10", value: "10" },
            { display: "20", value: "20" },
            { display: "30", value: "30" },
          ]
        },
        {
          name: "check_extra",
          label: "Extra Check Secs",
          description: "Extra seconds added to match window",
          default: "10",
          options: [
            { display: "10", value: "10" },
            { display: "20", value: "20" },
            { display: "30", value: "30" },
            { display: "60", value: "60" },
            { display: "120", value: "120" },
          ]
        },
        {
          name: "padding_key",
          label: "Padding Key",
          description: "Seconds before/after DVR job to trigger reminder",
          default: "10",
          options: [
            { display: "10", value: "10" },
            { display: "30", value: "30" },
          ]
        },
        { name: "apprise_url", label: "Apprise URL", default: "channels://", description: "Notification URL (channels:// = CHANNELS_CLIENTS)" },
        {
          name: "delete_job",
          label: "Delete Job",
          description: "Delete DVR job after notification",
          default: "false",
          options: [
            { display: "true", value: "true" },
            { display: "false", value: "false" },
          ]
        },
        { name: "channel_change", label: "Channel Change Client", default: "none", description: "Client hostname/IP for channel change (none = disabled)" },
      ],
    },
    {
      id: "marknocommercials",
      label: "Remove Comskip Markers",
      title: "Remove Comskip Markers from a Recording",
      arguments: [
        getDvrArgument(),
        { name: "file_id", label: "File ID", placeholder: "Enter File ID", description: "Library - TV Shows/Movies - <name> - Options - View Details - File ID" },
      ],
    },
    {
      id: "edlstrip",
      label: "Remove Commercials based on EDL",
      title: "Remove Commercials Based on an EDL File",
      arguments: [
        getDvrArgument(),
        { name: "input_path", label: "Input Path", default: "Movies", description: "Path relative to mounted dvr (e.g., TV/The Closer)" },
        { name: "input_filename", label: "Input Filename", placeholder: "Wild (2014) 2023-06-26-1900", description: "Recording filename (no .mpg extension)" },
        { name: "output_path", label: "Output Path", default: "Movies", description: "Output path relative to mounted dvr" },
        { name: "output_filename", label: "Output Filename", placeholder: "Wild (2014)", description: "Output filename (no .mkv extension)" },
      ],
    },
    {
      id: "restartshutdown",
      label: "Restart/Shutdown Server",
      title: "Restart or Shutdown a Channels DVR Server",
      arguments: [
        getDvrArgument(),
        {
          name: "action",
          label: "Action",
          description: "Force a restart or shutdown - current recordings will be terminated!",
          placeholder: "Select action...",
          options: [
            { display: "Restart", value: "force/restart" },
            { display: "Shutdown", value: "halt" },
          ]
        },
      ],
    },
    {
      id: "scanlocalcontent",
      label: "Scan/Prune Local Content",
      title: "Scan/Prune Local Content",
      arguments: [
        getDvrArgument(),
        {
          name: "action",
          label: "Action",
          description: "Scan or Prune local content",
          placeholder: "Select action...",
          options: [
            { display: "Scan", value: "scan" },
            { display: "Prune", value: "imports/prune" },
          ]
        },
      ],
    },
    {
      id: "pingcdvr",
      label: "Scheduled CDVR Server Ping",
      title: "Ping Channels DVR Server",
      arguments: [
        getDvrArgument(),
        { name: "interval", label: "Interval", default: "30m", description: "Ping interval (m for minutes, h for hours). once for single run. 0 to kill" },
        { name: "healthchecks_io", label: "Healthchecks URL", default: "https://hc-ping.com/your_custom_uuid", description: "Optional healthchecks.io ping URL", optional: true },
      ],
    },
    {
      id: "notifications",
      label: "Send Clients an Onscreen Message",
      title: "Send Message to Defined Channels Clients",
      arguments: [
        { name: "title", label: "Title", placeholder: "Enter message title", description: "Message title to send to all Channels DVR Clients" },
        { name: "message", label: "Message", placeholder: "Enter message body", description: "Message body" },
        { name: "duration", label: "Duration", placeholder: "Enter seconds", description: "Message duration in seconds" },
      ],
    },
    {
      id: "channels_to_csv_awk",
      label: "Single Channel Sources List",
      title: "List Sources for a Single Channel",
      arguments: [
        getDvrArgument(),
        { name: "channel", label: "Channel", placeholder: "hbo.*2", description: "Channel name (case insensitive, wildcard supported)" },
      ],
    },
    {
      id: "llc2metadata",
      label: "Update Metadata from LLC",
      title: "Update Commercials Metadata from LosslessCut LLC File",
      arguments: [
        getDvrArgument(),
        { name: "file_id", label: "File ID", placeholder: "Enter File ID", description: "DVR - Manage - <show> - <episode> - Options - View Details - File ID" },
      ],
    },
    {
      id: "updateprerelease",
      label: "Update to Pre-Release Automatically",
      title: "Keep CDVR Server Updated to Latest Pre-Release",
      arguments: [
        getDvrArgument(),
        { name: "interval", label: "Interval", default: "once", description: "Check interval (m for minutes, h for hours). once for single run. 0 to kill" },
        { name: "healthchecks_io", label: "Healthchecks URL", default: "https://hc-ping.com/your_custom_uuid", description: "Optional healthchecks.io ping URL", optional: true },
      ],
    },
    {
      id: "kisterupdates",
      label: "YouTube Live Manifest Updater",
      title: "Live YouTube Channel Manifest URL Updater",
      arguments: [
        getDvrArgument(),
        { name: "frequency", label: "Frequency", default: "5h", description: "Update interval (m for minutes, h for hours). 0 to kill" },
        { name: "channel_source_name", label: "Source Name", default: "YouTube Live", description: "Custom Channels Source name" },
        { name: "m3u_name", label: "M3U Filename", default: "YouTubeLive.m3u", description: "M3U file in data directory" },
      ],
    },
    {
      id: "youtube-process",
      label: "YouTube TubeArchivist Processor",
      title: "Tube Archivist CDVR Processor",
      arguments: [
        getDvrArgument(),
        { name: "frequency", label: "Frequency", default: "12h", description: "Processing interval (m for minutes, h for hours). once for single run. 0 to kill" },
        { name: "youtube_api_key", label: "YouTube API Key", default: "none", description: "Required. Your YouTube API Key" },
        { name: "apprise_url", label: "Apprise URL", default: "none", description: "Optional notification URL" },
        { name: "delete_after", label: "Delete After Days", default: "none", description: "Remove files older than x days (none = disabled)" },
        { name: "video_directory", label: "Video Directory", default: "tubearchivist", description: "Folder with TA downloads relative to TUBEARCHIVIST env" },
        { name: "channels_directory", label: "Channels Directory", default: "Imports/Videos", description: "Destination folder relative to TUBEARCHIVIST env" },
      ],
    },
  ];

  // One-Click project deployment actions (sorted alphabetically by label, Delete at bottom)
  const ONE_CLICK_ACTIONS = [
    {
      id: "adbtuner",
      label: "ADBTuner",
      title: "Create an ADBTuner Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "DOMAIN", label: "Domain", default: "localdomain", description: "Your LAN's domain (usually local or localdomain)" },
        { name: "HOST_PORT", label: "Host Port", default: "5592", description: "Use recommended port, or change if already in use" },
        { name: "HOST_VOLUME", label: "Host Volume", default: "adbtuner_config", description: "Filename for Docker volume" },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
      ],
    },
    {
      id: "adbtuner_directv_grabber",
      label: "ADBTuner DirecTV JSON",
      title: "Create an ADBTuner DirecTV JSON and its Channel Lineup",
      arguments: [
        getDvrArgument(),
        { name: "ADBTUNER_HOST", label: "ADBTuner Host", default: "${PORTAINER_HOST}", description: "Hostname or IP of host running ADBTuner" },
        { name: "ADBTUNER_PORT", label: "ADBTuner Port", default: "5592", description: "Port number ADBTuner is available on" },
        { name: "CURL_COMMAND", label: "Curl Command", placeholder: "Paste your DirecTV curl command", description: "Custom curl command to grab your DirecTV channel lineup" },
        { name: "CUSTOM_CONFIG", label: "Custom Config", placeholder: "Optional ADBTuner Custom Config JSON", description: "Paste ADBTuner Custom Config (with curly braces)", optional: true },
        {
          name: "DIRECTV_REMOVE",
          label: "Remove Existing",
          description: "Remove existing ADBTuner DirecTV channels first",
          default: "true",
          options: [
            { display: "true", value: "true" },
            { display: "false", value: "false" },
          ]
        },
        { name: "DTV_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
        {
          name: "DTV_CLIENT",
          label: "Client Type",
          description: "Streaming method or device type",
          default: "dtvnow://deeplink.directvnow.com/play/channel/",
          options: [
            { display: "App", value: "dtvnow://deeplink.directvnow.com/play/channel/" },
            { display: "Osprey", value: "https://deeplink.directvnow.com/tune/live/channel/" },
          ]
        },
      ],
    },
    {
      id: "adbtuner_sling_grabber",
      label: "ADBTuner Sling JSON",
      title: "Create an ADBTuner Sling JSON and its Channel Lineup",
      arguments: [
        getDvrArgument(),
        { name: "ADBTUNER_HOST", label: "ADBTuner Host", default: "${PORTAINER_HOST}", description: "Hostname or IP of host running ADBTuner" },
        { name: "ADBTUNER_PORT", label: "ADBTuner Port", default: "5592", description: "Port number ADBTuner is available on" },
        { name: "CURL_COMMAND", label: "Curl Command", placeholder: "Paste your Sling curl command", description: "Custom curl command to grab your Sling channel lineup" },
        {
          name: "CONFIG_NAME",
          label: "Config Name",
          description: "Choose a standard ADBTuner config, or Custom",
          default: "8ec77d65-30d6-46a3-8045-282571cff8d8",
          options: [
            { display: "Deep Links (default)", value: "8ec77d65-30d6-46a3-8045-282571cff8d8" },
            { display: "Deep Links - Show Tuning", value: "92c0c532-aa12-4d18-abbd-72e4a9cec15c" },
            { display: "Deep Links - Compatibility", value: "bb353259-17e0-4b38-a328-8629fb1ec2ca" },
            { display: "Compatibility - Show Tuning", value: "c513c18d-19bd-47f0-9bff-4baba2a8c4cd" },
          ]
        },
        { name: "CUSTOM_CONFIG", label: "Custom Config", placeholder: "Optional ADBTuner Custom Config JSON", description: "Paste ADBTuner Custom Config (with curly braces)", optional: true },
        {
          name: "SLING_REMOVE",
          label: "Remove Existing",
          description: "Remove existing ADBTuner Sling channels first",
          default: "true",
          options: [
            { display: "true", value: "true" },
            { display: "false", value: "false" },
          ]
        },
        { name: "SLING_START_CHAN", label: "Start Channel", default: "12000", description: "Starting channel number for Sling" },
      ],
    },
    {
      id: "ah4c",
      label: "ah4c (AndroidHDMI-for-Channels)",
      title: "Create an ah4c Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "DOMAIN", label: "Domain", default: "localdomain", description: "Your LAN's domain (usually local or localdomain)" },
        { name: "ADBS_PORT", label: "ADB Server Port", default: "5037", description: "Port for ADB Server" },
        { name: "HOST_PORT", label: "Host Port", default: "7654", description: "Port for ah4c" },
        { name: "SCRC_PORT", label: "SCRCPY Port", default: "7655", description: "Port for ws-scrcpy" },
        { name: "IPADDRESS", label: "IP Address", default: "${PORTAINER_HOST}:7654", description: "Hostname/IP of this ah4c extension for M3U" },
        { name: "NUMBER_TUNERS", label: "Number of Tuners", default: "2", description: "Number of tuners (1-9)" },
        { name: "TUNER1_IP", label: "Tuner 1 IP", default: "firestick-rack1:5555", description: "Streaming device #1 hostname:port" },
        { name: "ENCODER1_URL", label: "Encoder 1 URL", default: "http://encoder_48007/0.ts", description: "Full URL for tuner #1" },
        { name: "TUNER2_IP", label: "Tuner 2 IP", default: "#", description: "Streaming device #2 hostname:port (# for none)" },
        { name: "ENCODER2_URL", label: "Encoder 2 URL", default: "#", description: "Full URL for tuner #2 (# for none)" },
        { name: "STREAMER_APP", label: "Streamer App", default: "scripts/firetv/directv", description: "scripts/streamer/app path" },
        { name: "CHANNELSIP", label: "Channels IP", default: "${CHANNELS_DVR_HOST}", description: "Hostname/IP of Channels DVR server" },
        { name: "ALERT_SMTP_SERVER", label: "SMTP Server", default: "smtp.gmail.com:587", description: "SMTP server for alerts (# for none)" },
        { name: "ALERT_AUTH_SERVER", label: "Auth Server", default: "smtp.gmail.com", description: "Auth server for email (# for none)" },
        { name: "ALERT_EMAIL_FROM", label: "Email From", default: "#", description: "Alert email sender (# for none)" },
        { name: "ALERT_EMAIL_PASS", label: "Email Password", default: "#", description: "App-specific email password (# for none)" },
        { name: "ALERT_EMAIL_TO", label: "Email To", default: "#", description: "Alert email recipient (# for none)" },
        { name: "TZ", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format" },
        { name: "HOST_DIR", label: "Host Dir", default: "/data", description: "Parent directory for persistent data" },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
        { name: "CDVR_M3U_NAME", label: "M3U Filename", default: "directv.m3u", description: "M3U file name for CDVR Custom Channels" },
      ],
    },
    {
      id: "cc4c",
      label: "cc4c (ChromeCapture-for-Channels)",
      title: "Create a cc4c Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "5589", description: "Use recommended port, or change if already in use" },
        { name: "CC4C_PORT", label: "CC4C Port", default: "5589", description: "Port for the server inside the container" },
        { name: "HOST_VNC_PORT", label: "VNC Port", default: "5900", description: "VNC port for entering credentials" },
        { name: "VIDEO_BITRATE", label: "Video Bitrate", default: "6000000", description: "Video bitrate in bits per second" },
        { name: "AUDIO_BITRATE", label: "Audio Bitrate", default: "256000", description: "Audio bitrate in bits per second" },
        { name: "FRAMERATE", label: "Framerate", default: "30", description: "Minimum frame rate" },
        { name: "VIDEO_WIDTH", label: "Video Width", default: "1920", description: "Video width in pixels" },
        { name: "VIDEO_HEIGHT", label: "Video Height", default: "1080", description: "Video height in pixels" },
        {
          name: "VIDEO_CODEC",
          label: "Video Codec",
          description: "Video codec to use",
          default: "h264_nvenc",
          options: [
            { display: "h264_nvenc", value: "h264_nvenc" },
            { display: "h264_qsv", value: "h264_qsv" },
            { display: "h264_amf", value: "h264_amf" },
            { display: "h264_vaapi", value: "h264_vaapi" },
          ]
        },
        {
          name: "AUDIO_CODEC",
          label: "Audio Codec",
          description: "Audio codec to use",
          default: "aac",
          options: [
            { display: "aac", value: "aac" },
            { display: "opus", value: "opus" },
          ]
        },
        { name: "TZ", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format" },
        {
          name: "DEVICES",
          label: "Devices",
          description: "Intel Quick Sync support",
          default: "#",
          options: [
            { display: "/dev/dri", value: "true" },
            { display: "none", value: "#" },
          ]
        },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
      ],
    },
    {
      id: "channels-remote-plus",
      label: "Channels-App-Remote-Plus",
      title: "Create a Channels-App-Remote-Plus Stack in Portainer",
      arguments: [
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "5000", description: "Use recommended port, or change if already in use" },
      ],
    },
    {
      id: "channels-dvr",
      label: "Channels-DVR",
      title: "Create a Channels DVR Stack in Portainer",
      arguments: [
        { name: "TAG", label: "Tag", default: "tve", description: "The version of the container (latest or tve)" },
        { name: "HOST_PORT", label: "Host Port", default: "8089", description: "Use recommended port, or change if already in use" },
        { name: "CHANNELS_PORT", label: "Channels Port", default: "8089", description: "Port number when using host mode" },
        { name: "TZ", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format" },
        { name: "HOST_DIR", label: "Host Dir", default: "/data", description: "Parent directory for persistent data" },
        { name: "DVR_SHARE", label: "DVR Share", default: "/mnt/dvr", description: "Volume name or path to DVR files" },
        { name: "DVR_CONTAINER_DIR", label: "Container Dir", default: "/shares/DVR", description: "Directory inside container for DVR files" },
        { name: "VOL_EXTERNAL", label: "Volume External", default: "#", description: "Set to true if volume managed separately (# for none)" },
        { name: "VOL_NAME", label: "Volume Name", default: "#", description: "Filesystem name for Docker volume (# for none)" },
        {
          name: "NETWORK_MODE",
          label: "Network Mode",
          description: "Use host for LAN discovery, bridge otherwise",
          default: "#",
          options: [
            { display: "bridge", value: "#" },
            { display: "host", value: "host" },
          ]
        },
        {
          name: "DEVICES",
          label: "Devices",
          description: "Intel Quick Sync support for transcoding",
          default: "#",
          options: [
            { display: "/dev/dri", value: "true" },
            { display: "none", value: "#" },
          ]
        },
        {
          name: "CDVR_CONTAINER",
          label: "Container Number",
          description: "For multiple CDVR containers on same host",
          default: "#",
          options: [
            { display: "#", value: "#" },
            { display: "1", value: "1" },
            { display: "2", value: "2" },
            { display: "3", value: "3" },
          ]
        },
      ],
    },
    {
      id: "debuglogs",
      label: "Debug Log Viewer",
      title: "Project One-Click Actions Debug Log Viewer",
      arguments: [
        {
          name: "action",
          label: "Action",
          description: "Select the One-Click Action to view debug log",
          placeholder: "Select action...",
          options: [
            { display: "ADBTuner", value: "adbtuner" },
            { display: "ADBTuner DirecTV", value: "adbtuner_directv_grabber" },
            { display: "ADBTuner Sling", value: "adbtuner_sling_grabber" },
            { display: "ah4c", value: "ah4c" },
            { display: "Channels-App-Remote-Plus", value: "channels-app-remote-plus" },
            { display: "Channels DVR", value: "channels-dvr" },
            { display: "cc4c", value: "cc4c" },
            { display: "EPlusTV", value: "eplustv" },
            { display: "ESPN4cc4c", value: "espn4cc4c" },
            { display: "FileBot", value: "filebot" },
            { display: "FrndlyTV-for-Channels", value: "frndlytv-for-channels" },
            { display: "FruitDeepLinks", value: "fruitdeeplinks" },
            { display: "MediaInfo", value: "mediainfo" },
            { display: "mlbserver", value: "mlbserver" },
            { display: "Organizr", value: "organizr" },
            { display: "Pinchflat", value: "pinchflat" },
            { display: "Plex-for-Channels", value: "plex-for-channels" },
            { display: "Pluto-for-Channels", value: "pluto-for-channels" },
            { display: "PrismCast", value: "prismcast" },
            { display: "Roku-Channels-Bridge", value: "roku-channels-bridge" },
            { display: "Samsung-TVPlus", value: "samsung-tvplus-for-channels" },
            { display: "Stream Link Manager", value: "slm" },
            { display: "Threadfin", value: "threadfin" },
            { display: "TubeArchivist", value: "tubearchivist" },
            { display: "Tubi-for-Channels", value: "tubi-for-channels" },
            { display: "TV-Logo-Manager", value: "tv-logo-manager" },
            { display: "VLC-Bridge-Fubo", value: "vlc-bridge-fubo" },
            { display: "VLC-Bridge-PBS", value: "vlc-bridge-pbs" },
            { display: "Watchtower", value: "watchtower" },
            { display: "WeatherStar 4000+", value: "weatherstar4k" },
            { display: "Youtub3r", value: "youtub3r" },
            { display: "One-Click Delete", value: "one-click_delete" },
          ]
        },
      ],
    },
    {
      id: "dockercompose",
      label: "Docker-Compose Examples",
      title: "Docker-Compose Examples for CDVR & Related Extensions",
      arguments: [
        {
          name: "project",
          label: "Project",
          description: "Select project for Docker-Compose example",
          placeholder: "Select project...",
          options: [
            { display: "ADBTuner", value: "adbtuner" },
            { display: "ah4c", value: "ah4c" },
            { display: "cc4c", value: "cc4c" },
            { display: "ChannelWatch", value: "channelwatch" },
            { display: "EPlusTV", value: "eplustv" },
            { display: "FileBot", value: "filebot" },
            { display: "FrndlyTV-for-Channels", value: "frndlytv-for-channels" },
            { display: "MediaInfo", value: "mediainfo" },
            { display: "mlbserver", value: "mlbserver" },
            { display: "OliveTin-for-Channels", value: "olivetin-for-channels" },
            { display: "Organizr", value: "organizr" },
            { display: "Plex-for-Channels", value: "plex-for-channels" },
            { display: "Pluto-for-Channels (jonmaddox)", value: "pluto" },
            { display: "Pluto-for-Channels (joagomez)", value: "pluto-for-channels" },
            { display: "PrismCast", value: "prismcast" },
            { display: "Roku-Channels-Bridge", value: "roku-channels-bridge" },
            { display: "Samsung-TVPlus-for-Channels", value: "samsung-tvplus-for-channels" },
            { display: "Stirr-for-Channels", value: "stirr-for-channels" },
            { display: "Stream-Link-Manager", value: "slm" },
            { display: "Tailscale", value: "tailscale" },
            { display: "Threadfin", value: "threadfin" },
            { display: "TubeArchivist", value: "tubearchivist" },
            { display: "Tubi-for-Channels", value: "tubi-for-channels" },
            { display: "VLC-Bridge-PBS", value: "vlc-bridge-pbs" },
            { display: "VLC-Bridge-Fubo", value: "vlc-bridge-fubo" },
            { display: "Watchtower", value: "watchtower" },
          ]
        },
      ],
    },
    {
      id: "eplustv",
      label: "EPlusTV",
      title: "Create an EPlusTV Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "8020", description: "Use recommended port, or change if already in use" },
        { name: "START_CHANNEL", label: "Start Channel", default: "1", description: "What the first channel number should be" },
        { name: "NUM_OF_CHANNELS", label: "Num of Channels", default: "200", description: "How many channels to create" },
        { name: "LINEAR_CHANNELS", label: "Linear Channels", default: "false", description: "Break out dedicated linear channels" },
        { name: "BASE_URL", label: "Base URL", default: "default", description: "Keep as default, or set for reverse proxy" },
        { name: "PROXY_SEGMENTS", label: "Proxy Segments", default: "false", description: "Proxy keyed *.ts files" },
        { name: "PUID", label: "PUID", default: "1000", description: "User ID for permissions" },
        { name: "PGID", label: "PGID", default: "1000", description: "Group ID for permissions" },
        { name: "PORT", label: "API Port", default: "8000", description: "Port the API will be served on" },
        { name: "HOST_VOLUME", label: "Host Volume", default: "eplustv_config", description: "Filename for Docker volume" },
      ],
    },
    {
      id: "espn4cc4c",
      label: "ESPN4cc4c",
      title: "Create an ESPN4cc4c Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "DOMAIN", label: "Domain", default: "localdomain", description: "Your LAN's domain (usually local or localdomain)" },
        { name: "HOST_PORT", label: "Host Port", default: "8094", description: "Use recommended port, or change if already in use" },
        { name: "TZ", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format" },
        { name: "VC_RESOLVER_BASE", label: "Base URL", default: "http://htpc6:8094", description: "Base URL for this project" },
        { name: "CC_HOST", label: "cc4c Host", default: "cc4c", description: "Hostname/IP for cc4c (or leave as cc4c)" },
        { name: "CC_PORT", label: "cc4c Port", default: "5589", description: "Port for cc4c" },
        { name: "CH4C_HOST", label: "ch4c Host", default: "ch4c", description: "Hostname/IP for ch4c (or leave as ch4c)" },
        { name: "CH4C_PORT", label: "ch4c Port", default: "2442", description: "Port for ch4c" },
        { name: "LANES", label: "Lanes", default: "40", description: "Number of virtual channels for ESPN+ events" },
        {
          name: "EXCLUDE_REAIR",
          label: "Exclude Re-Airs",
          description: "Re-Airs cannot be viewed via ADBTuner deeplinks",
          default: "true",
          options: [
            { display: "true", value: "true" },
            { display: "false", value: "false" },
          ]
        },
        { name: "HOST_DIR", label: "Host Dir", default: "/data/espn4cc4c", description: "Parent directory for persistent data" },
        {
          name: "ESPN4cc4c_SOURCE",
          label: "cc4c Source",
          description: "Create CDVR Custom Channels Source via cc4c",
          default: "false",
          options: [
            { display: "true", value: "true" },
            { display: "false", value: "false" },
          ]
        },
        { name: "CC4C_START_CHAN", label: "cc4c Start Chan", default: "#", description: "Override cc4c M3U channel numbers. Use # for default" },
        {
          name: "ESPN4ch4c_SOURCE",
          label: "ch4c Source",
          description: "Create CDVR Custom Channels Source via ch4c",
          default: "false",
          options: [
            { display: "true", value: "true" },
            { display: "false", value: "false" },
          ]
        },
        { name: "CH4C_START_CHAN", label: "ch4c Start Chan", default: "#", description: "Override ch4c M3U channel numbers. Use # for default" },
      ],
    },
    {
      id: "frndlytv-for-channels",
      label: "FrndlyTV-for-Channels",
      title: "Create a FrndlyTV-for-Channels Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "8183", description: "Use recommended port, or change if already in use" },
        { name: "IP", label: "IP Override", default: "#", description: "For Geo-locating FrndlyTV to a different area. Use # for none" },
        { name: "USERNAME", label: "Username", default: "username@email.com", description: "FrndlyTV username (email you used to sign-up)" },
        { name: "PASSWORD", label: "Password", default: "password", description: "FrndlyTV password" },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers starting here. Use # for M3U numbering" },
        {
          name: "FRNDLYTV_PLAN",
          label: "Plan",
          description: "Select based on your FrndlyTV package",
          placeholder: "Select plan...",
          default: "2",
          options: [
            { display: "Basic Plan (one stream)", value: "1" },
            { display: "Classic Plan (two streams)", value: "2" },
            { display: "Premium Plan (four streams)", value: "4" },
          ]
        },
      ],
    },
    {
      id: "fruitdeeplinks",
      label: "FruitDeepLinks",
      title: "Create a FruitDeepLinks Stack in Portainer",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "DOMAIN", label: "Domain", default: "localdomain", description: "Your LAN's domain (usually local or localdomain)" },
        { name: "HOST_PORT", label: "Host Port", default: "6655", description: "Use recommended port, or change if already in use" },
        { name: "TZ", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format" },
        { name: "SERVER_URL", label: "Server URL", default: "http://htpc6:6655", description: "FruitDeepLinks base URL" },
        { name: "CC_SERVER", label: "cc4c Server", default: "cc4c", description: "Hostname/IP for cc4c integration (or leave as cc4c)" },
        { name: "CC_PORT", label: "cc4c Port", default: "5589", description: "Port for cc4c" },
        { name: "FRUIT_LANES", label: "Lanes", default: "50", description: "Number of virtual channels for FRUIT events" },
        { name: "CHANNELS_DVR_PATH", label: "DVR Path", placeholder: "Optional - for detector feature", description: "Mount DVR path for CDVR detector", optional: true },
        {
          name: "AUTO_REFRESH",
          label: "Auto Refresh",
          description: "Enable automatic refreshing every 24 hours",
          default: "true",
          options: [
            { display: "true", value: "true" },
            { display: "false", value: "false" },
          ]
        },
        { name: "AUTO_REFRESH_TIME", label: "Refresh Time", default: "2:30", description: "Time of day for automatic refresh" },
        { name: "HOST_DIR", label: "Host Dir", default: "/data", description: "Parent directory for persistent data" },
        { name: "FRUIT_START_CHAN", label: "Start Channel", default: "14001", description: "Starting channel number for CDVR Custom Channels" },
      ],
    },
    {
      id: "filebot",
      label: "FileBot",
      title: "Create a FileBot Stack in Portainer",
      arguments: [
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "5800", description: "Use recommended port, or change if already in use" },
        { name: "DARK_MODE", label: "Dark Mode", default: "1", description: "Set to 1 to enable dark mode" },
        { name: "HOST_DIR", label: "Host Dir", default: "/data", description: "Parent directory for persistent data" },
        { name: "DVR_SHARE", label: "DVR Share", default: "/mnt/dvr", description: "Volume name or path to DVR files" },
        { name: "VOL_EXTERNAL", label: "Volume External", default: "#", description: "Set to true if volume managed separately (# for none)" },
        { name: "VOL_NAME", label: "Volume Name", default: "#", description: "Filesystem name for Docker volume (# for none)" },
      ],
    },
    {
      id: "mediainfo",
      label: "MediaInfo",
      title: "Create a MediaInfo Stack in Portainer",
      arguments: [
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "5801", description: "Use recommended port, or change if already in use" },
        { name: "DARK_MODE", label: "Dark Mode", default: "1", description: "Set to 1 to enable dark mode" },
        { name: "HOST_DIR", label: "Host Dir", default: "/data", description: "Parent directory for persistent data" },
        { name: "DVR_SHARE", label: "DVR Share", default: "/mnt/dvr", description: "Volume name or path to DVR files" },
        { name: "VOL_EXTERNAL", label: "Volume External", default: "#", description: "Set to true if volume managed separately (# for none)" },
        { name: "VOL_NAME", label: "Volume Name", default: "#", description: "Filesystem name for Docker volume (# for none)" },
      ],
    },
    {
      id: "mlbserver",
      label: "mlbserver",
      title: "Create an mlbserver Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "9999", description: "Use recommended port, or change if already in use" },
        { name: "TIMEZONE", label: "Timezone", default: "America/Denver", description: "In Linux Continent/City format" },
        { name: "DATA_DIRECTORY", label: "Data Directory", default: "/mlbserver/data_directory", description: "Path for mlbserver data inside container" },
        { name: "ACCOUNT_USERNAME", label: "Username", default: "username@email.com", description: "Your MLB.tv username" },
        { name: "ACCOUNT_PASSWORD", label: "Password", default: "password", description: "Your MLB.tv password" },
        { name: "FAV_TEAMS", label: "Favorite Teams", default: "0", description: "Comma-separated list (ATL,AZ,BAL,BOS,etc) or 0 for none" },
        { name: "HOST_DIR", label: "Host Dir", default: "/data", description: "Parent directory for persistent data" },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
      ],
    },
    {
      id: "organizr",
      label: "Organizr",
      title: "Create an Organizr Stack in Portainer",
      arguments: [
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "80", description: "Use recommended port, or change if already in use" },
        { name: "TZ", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format" },
        { name: "HOST_DIR", label: "Host Dir", default: "/data", description: "Parent directory for persistent data" },
      ],
    },
    {
      id: "pinchflat",
      label: "Pinchflat",
      title: "Create a Pinchflat Stack in Portainer",
      arguments: [
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "8945", description: "Use recommended port, or change if already in use" },
        { name: "TZ", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format" },
        { name: "HOST_DIR", label: "Host Dir", default: "/data", description: "Parent directory for persistent data" },
        { name: "VIDEOS_SHARE", label: "Videos Share", default: "/mnt/videos", description: "Volume name or path for video files" },
      ],
    },
    {
      id: "plex-for-channels",
      label: "Plex-for-Channels",
      title: "Create a Plex-for-Channels Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "7779", description: "Use recommended port, or change if already in use" },
        { name: "PORT", label: "Internal Port", default: "7777", description: "Port the container uses internally" },
        { name: "REGIONS", label: "Regions", default: "local", description: "M3U options (local,nyc,clt,dfw,la,sea,ca,uk,nz,au,mx,es)" },
        {
          name: "MJH_COMPATIBILITY",
          label: "MJH Compatibility",
          description: "Compatibility with legacy Matt Huisman Plex playlist",
          default: "false",
          options: [
            { display: "true", value: "true" },
            { display: "false", value: "false" },
          ]
        },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
        { name: "HOST_DIR", label: "Host Dir", default: "/data", description: "Parent directory for persistent data" },
      ],
    },
    {
      id: "pluto-for-channels",
      label: "Pluto-for-Channels",
      title: "Create a Pluto-for-Channels Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "7780", description: "Use recommended port, or change if already in use" },
        { name: "PLUTO_PORT", label: "Pluto Port", default: "7777", description: "Change the port this container uses internally" },
        { name: "PLUTO_CODE", label: "Country Code", default: "local", description: "Country streams to host (local,us_west,us_east,ca,uk) - comma separated" },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers starting here. Use # for M3U numbering" },
      ],
    },
    {
      id: "prismcast",
      label: "PrismCast",
      title: "Create a PrismCast Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "DOMAIN", label: "Domain", default: "localdomain", description: "Your LAN's domain (usually local or localdomain)" },
        { name: "HOST_PORT", label: "Host Port", default: "5589", description: "Use recommended port, or change if already in use" },
        { name: "HOST_VNC_PORT", label: "VNC Port", default: "5900", description: "Use recommended port, or change if already in use" },
        { name: "HOST_NOVNC_PORT", label: "noVNC Port", default: "6080", description: "Use recommended port, or change if already in use" },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
      ],
    },
    {
      id: "roku-ecp-tuner",
      label: "Roku-Channels-Bridge",
      title: "Create a Roku-Channels-Bridge Stack in Portainer",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "5006", description: "Use recommended port, or change if already in use" },
        {
          name: "ENCODING_MODE",
          label: "Encoding Mode",
          description: "Set a global, default stream handling mode",
          default: "proxy",
          options: [
            { display: "proxy", value: "proxy" },
            { display: "remux", value: "remux" },
            { display: "reencode", value: "reencode" },
          ]
        },
        { name: "AUDIO_BITRATE", label: "Audio Bitrate", default: "192k", description: "Set audio quality for reencode mode" },
        {
          name: "AUDIO_CHANNELS",
          label: "Audio Channels",
          description: "Set the number of audio channels",
          default: "5.1",
          options: [
            { display: "5.1", value: "5.1" },
            { display: "7.1", value: "7.1" },
          ]
        },
        {
          name: "ENABLE_DEBUG_LOGGING",
          label: "Debug Logging",
          description: "Set to true for detailed logs",
          default: "false",
          options: [
            { display: "true", value: "true" },
            { display: "false", value: "false" },
          ]
        },
        { name: "HOST_VOLUME", label: "Host Volume", default: "roku-channels-bridge", description: "Filename for Docker volume" },
        {
          name: "DEVICES",
          label: "Devices",
          description: "If your Docker host supports Intel Quick Sync for transcoding",
          default: "#",
          options: [
            { display: "/dev/dri", value: "true" },
            { display: "none", value: "#" },
          ]
        },
      ],
    },
    {
      id: "samsung-tvplus-for-channels",
      label: "Samsung-TVPlus-for-Channels",
      title: "Create a Samsung-TVPlus-for-Channels Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "8182", description: "Use recommended port, or change if already in use" },
        { name: "REGIONS", label: "Regions", default: "us", description: "List desired region streams (us|kr|it|in|gb|fr|es|de|ch|ca|at) or all" },
        { name: "TZ", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format" },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
      ],
    },
    {
      id: "stream-link-manager-for-channels",
      label: "Stream-Link-Manager-for-Channels",
      title: "Create a Stream Link Manager Stack in Portainer",
      arguments: [
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "SLM_PORT", label: "SLM Port", default: "5000", description: "Use recommended port, or change if already in use" },
        { name: "TIMEZONE", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format" },
        { name: "SLM_HOST_FOLDER", label: "SLM Host Folder", default: "slm_files", description: "Volume name or path for SLM program files" },
        { name: "CHANNELS_FOLDER", label: "Channels Folder", default: "/mnt/dvr", description: "Volume name or path to DVR files" },
      ],
    },
    {
      id: "threadfin",
      label: "Threadfin",
      title: "Create a Threadfin Stack in Portainer",
      arguments: [
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "34400", description: "Use recommended port, or change if already in use" },
        { name: "PUID", label: "PUID", default: "1001", description: "User ID for permissions" },
        { name: "PGID", label: "PGID", default: "1001", description: "Group ID for permissions" },
        { name: "TZ", label: "Timezone", default: "America/Denver", description: "Your local timezone (Continent/City format)" },
        { name: "HOST_DIR", label: "Host Dir", default: "/data", description: "Parent directory for persistent data" },
      ],
    },
    {
      id: "tubearchivist",
      label: "TubeArchivist",
      title: "Create a TubeArchivist Stack in Portainer",
      arguments: [
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "8010", description: "Use recommended port, or change if already in use" },
        { name: "ES_PORT", label: "ElasticSearch Port", default: "9200", description: "Port for ElasticSearch" },
        { name: "REDIS_PORT", label: "Redis Port", default: "6379", description: "Port for Redis" },
        { name: "TA_HOST", label: "TA Host", default: "${PORTAINER_HOST}", description: "TubeArchivist hostname for WebUI access" },
        { name: "TA_USERNAME", label: "TA Username", default: "tubearchivist", description: "TubeArchivist login username" },
        { name: "TA_PASSWORD", label: "TA Password", default: "ChannelsDVR", description: "TubeArchivist login password" },
        { name: "TZ", label: "Timezone", default: "America/Denver", description: "Your local timezone (Continent/City format)" },
        { name: "HOST_DIR", label: "Host Dir", default: "/mnt/dvr", description: "Parent directory for downloaded videos" },
      ],
    },
    {
      id: "tubi-for-channels",
      label: "Tubi-for-Channels",
      title: "Create a Tubi-for-Channels Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "7778", description: "Use recommended port, or change if already in use" },
        { name: "TUBI_PORT", label: "Tubi Port", default: "7777", description: "Change the port this container uses internally" },
        { name: "TUBI_USER", label: "Tubi Username", default: "none", description: "Optional. Tubi username (leave as none for blank)" },
        { name: "TUBI_PASS", label: "Tubi Password", default: "none", description: "Optional. Tubi password (leave as none for blank)" },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
      ],
    },
    {
      id: "tv-logo-manager",
      label: "TV-Logo-Manager",
      title: "Create a TV-Logo-Manager Stack in Portainer",
      arguments: [
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "8084", description: "Use recommended port, or change if already in use" },
        { name: "CLOUD_NAME", label: "Cloud Name", placeholder: "Enter Cloudinary Cloud name", description: "Cloudinary Cloud name" },
        { name: "API_KEY", label: "API Key", placeholder: "Enter Cloudinary API key", description: "Cloudinary Cloud API key" },
        { name: "API_SECRET", label: "API Secret", placeholder: "Enter Cloudinary API secret", description: "Cloudinary Cloud API secret" },
        { name: "TZ", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format (Continent/City)" },
        { name: "HOST_DIR", label: "Host Dir", default: "/data", description: "Parent directory for persistent data" },
      ],
    },
    {
      id: "vlc-bridge-fubo",
      label: "VLC-Bridge-Fubo",
      title: "Create a VLC-Bridge-Fubo Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "7777", description: "Use recommended port, or change if already in use" },
        { name: "FUBO_USER", label: "Fubo Username", default: "username@email.com", description: "Fubo username (email you used to sign-up)" },
        { name: "FUBO_PASS", label: "Fubo Password", default: "password", description: "Fubo password" },
        { name: "HOST_VOLUME", label: "Host Volume", default: "vlc-bridge-fubo_config", description: "Filename for Docker volume" },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
      ],
    },
    {
      id: "vlc-bridge-pbs",
      label: "VLC-Bridge-PBS",
      title: "Create a VLC-Bridge-PBS Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "7777", description: "Use recommended port, or change if already in use" },
        { name: "TZ", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format" },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
      ],
    },
    {
      id: "watchtower",
      label: "Watchtower",
      title: "Create a Watchtower Stack in Portainer",
      arguments: [
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        {
          name: "WT_RUN_ONCE",
          label: "Run Once",
          description: "Set to true for on-demand only (recommended)",
          default: "true",
          options: [
            { display: "true", value: "true" },
            { display: "false", value: "false" },
          ]
        },
      ],
    },
    {
      id: "weatherstar4k",
      label: "WeatherStar 4000+",
      title: "Create a WeatherStar 4000+ Stack in Portainer + CDVR Custom Channels",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "HOST_PORT", label: "Host Port", default: "8080", description: "Use recommended port, or change if already in use" },
        { name: "TZ", label: "Timezone", default: "US/Mountain", description: "Your local timezone in Linux tz format" },
        { name: "CDVR_START_CHAN", label: "Start Channel", default: "#", description: "Override M3U channel numbers. Use # for default" },
        { name: "CC4C_HOST_PORT", label: "cc4c Host:Port", default: "cc4c:5589", description: "IP/Hostname and port of cc4c installation" },
      ],
    },
    {
      id: "youtub3r",
      label: "Youtub3r",
      title: "Create a Youtub3r Stack in Portainer",
      arguments: [
        getDvrArgument(),
        { name: "TAG", label: "Tag", default: "latest", description: "The version of the container you'd like to run" },
        { name: "WAIT_IN_SECONDS", label: "Wait Seconds", default: "60", description: "Seconds between scans" },
        { name: "YOUTUBE_SHARE", label: "YouTube Share", default: "/mnt/videos", description: "Parent directory for YouTube videos" },
      ],
    },
    // Delete action at the bottom
    {
      id: "one-click-delete",
      label: "Delete a Project",
      title: "Delete a Project One-Click Channels DVR Extension",
      arguments: [
        getDvrArgument(),
        {
          name: "project",
          label: "Project",
          description: "Select the project you'd like to delete",
          placeholder: "Select project...",
          options: [
            { display: "ADBTuner", value: "adbtuner+adbtuner:latest+ADBTuner" },
            { display: "ah4c (AndroidHDMI-for-Channels)", value: "ah4c+ah4c:latest" },
            { display: "Channels-App-Remote", value: "channels-app-remote+channels-app-remote:latest" },
            { display: "Channels-App-Remote-Plus", value: "channels-app-remote-plus+channels-remote-plus:latest" },
            { display: "ChannelWatch", value: "channelwatch+channelwatch:latest" },
            { display: "cc4c (ChromeCapture-for-Channels)", value: "cc4c+cc4c:latest+cc4c" },
            { display: "EPlusTV", value: "eplustv+eplustv:latest+EPlusTV+EPlusTV-Linear" },
            { display: "ESPN4cc4c", value: "espn4cc4c+espn4cc4c:latest+ESPN4cc4c+ESPN4ch4c" },
            { display: "FileBot", value: "filebot+filebot:latest" },
            { display: "FrndlyTV-for-Channels", value: "frndlytv-for-channels+frndlytv-for-channels:latest+FrndlyTV+FrndlyTV-NoEPG" },
            { display: "MediaInfo", value: "mediainfo+mediainfo:latest" },
            { display: "MLB.tv-for-Channels", value: "mlb.tv-for-channels+channels-baseball:latest+MLB.tv" },
            { display: "mlbserver", value: "mlbserver+mlbserver:latest+mlbserver" },
            { display: "Multi4Channels", value: "multi4channels+multi4channels:v22+multi4channels" },
            { display: "Multichannel View", value: "multichannelview+multichannelview:latest+multichannelview" },
            { display: "Organizr", value: "organizr+organizr:latest" },
            { display: "Pinchflat", value: "pinchflat+pinchflat:latest" },
            { display: "Plex-for-Channels", value: "plex-for-channels+plex-for-channels:latest+PlexTV+PlexTV-NoEPG" },
            { display: "Pluto-for-Channels (jonmaddox)", value: "pluto+jonmaddox/pluto-for-channels:latest" },
            { display: "Pluto-for-Channels (joagomez)", value: "pluto-for-channels+jgomez177/pluto-for-channels:latest+PlutoTV" },
            { display: "Pluto-for-Channels2 (bobby_vaughn)", value: "pluto-for-channels2+rcvaughn2/pluto-for-channels:main+PlutoTV2" },
            { display: "PrismCast", value: "prismcast+prismcast:latest+PrismCast" },
            { display: "Roku-Channels-Bridge", value: "roku-channels-bridge+rcvaughn2/roku-ecp-tuner:latest" },
            { display: "SamsungTVPlus-for-Channels", value: "samsung-tvplus-for-channels+samsung-tvplus-for-channels:latest+SamsungTVPlus" },
            { display: "Stirr-for-Channels", value: "stirr-for-channels+stirr-for-channels:latest+StirrTV" },
            { display: "Stream-Link-Manager-for-Channels", value: "slm+stream-link-manager-for-channels:latest" },
            { display: "Tailscale", value: "tailscale+tailscale:latest" },
            { display: "Threadfin", value: "threadfin+threadfin:latest" },
            { display: "TubeArchivist", value: "tubearchivist+tubearchivist:latest" },
            { display: "Tubi-for-Channels", value: "tubi-for-channels+tubi-for-channels:latest+TubiTV+TubiTV-NoEPG" },
            { display: "TV-Logo-Manager", value: "tv-logo-manager+tv-logo-manager:latest" },
            { display: "VLC-Bridge-PBS", value: "vlc-bridge-pbs+vlc-bridge-pbs:latest+PBS" },
            { display: "VLC-Bridge-Fubo", value: "vlc-bridge-fubo+vlc-bridge-fubo:latest+FuboTV" },
            { display: "VLC-Bridge-UK", value: "vlc-bridge-uk+vlc-bridge-uk:latest" },
            { display: "Watchtower", value: "watchtower+watchtower:latest" },
            { display: "WeatherStar 4000+", value: "weatherstar4k+ghcr.io/netbymatt/ws4kp:latest+WeatherStar4K" },
            { display: "Youtub3r", value: "youtub3r+youtub3r:latest" },
          ]
        },
      ],
    },
  ];

  // ============================================================
  // INTERNAL CONSTANTS (no need to edit below)
  // ============================================================

  // OliveTin dropdown IDs
  const NAV_ITEM_ID = "tm-olivetin-nav-item";
  const TOGGLE_ID = "tm-olivetin-nav-dropdown";
  const MENU_ID = "tm-olivetin-dropdown-menu";

  // One-Click dropdown IDs
  const ONECLICK_NAV_ITEM_ID = "tm-oneclick-nav-item";
  const ONECLICK_TOGGLE_ID = "tm-oneclick-nav-dropdown";
  const ONECLICK_MENU_ID = "tm-oneclick-dropdown-menu";

  // ============================================================
  // HTTP HELPER
  // ============================================================

  function gmPostJson(url, bodyObj) {
    return new Promise((resolve, reject) => {
      GM_xmlhttpRequest({
        method: "POST",
        url,
        headers: { "Content-Type": "application/json" },
        data: JSON.stringify(bodyObj),
        onload: (resp) => {
          if (resp.status >= 200 && resp.status < 300) resolve(resp.responseText);
          else reject(new Error(`HTTP ${resp.status}: ${resp.responseText}`));
        },
        onerror: () => reject(new Error("Network error")),
      });
    });
  }

  // Fetch the list of green icon action IDs from OliveTin
  async function fetchGreenIcons() {
    return new Promise((resolve) => {
      GM_xmlhttpRequest({
        method: "GET",
        url: `${OLIVETIN_BASE}/api/StartActionByGetAndWait/listgreenicons`,
        timeout: 5000,
        onload: (resp) => {
          if (resp.status >= 200 && resp.status < 300) {
            try {
              const obj = JSON.parse(resp.responseText);
              const output = obj?.logEntry?.output ?? "";
              // Parse linefeed-separated list of action IDs
              const greenIds = output.trim().split(/\r?\n/).filter(s => s.length > 0);
              resolve(greenIds);
            } catch {
              resolve([]);
            }
          } else {
            resolve([]);
          }
        },
        onerror: () => resolve([]),
        ontimeout: () => resolve([]),
      });
    });
  }

  // Update dropdown menu items with green indicators
  function updateMenuGreenIndicators(menu, greenIds) {
    const greenSet = new Set(greenIds);
    menu.querySelectorAll(".dropdown-item[data-action-id]").forEach(item => {
      const actionId = item.dataset.actionId;
      const isGreen = greenSet.has(actionId);
      // Update or add the indicator span
      let indicator = item.querySelector(".tm-action-indicator");
      if (!indicator) {
        indicator = document.createElement("span");
        indicator.className = "tm-action-indicator";
        indicator.style.marginRight = "6px";
        item.prepend(indicator);
      }
      if (isGreen) {
        indicator.style.color = "#4CAF50";
        indicator.textContent = "●";
      } else {
        indicator.style.color = "";
        indicator.textContent = "";
      }
    });
  }

  // Fetch the list of running container IDs from OliveTin
  async function fetchRunningContainers() {
    return new Promise((resolve) => {
      GM_xmlhttpRequest({
        method: "GET",
        url: `${OLIVETIN_BASE}/api/StartActionByGetAndWait/listrunningcontainers`,
        timeout: 5000,
        onload: (resp) => {
          if (resp.status >= 200 && resp.status < 300) {
            try {
              const obj = JSON.parse(resp.responseText);
              const output = obj?.logEntry?.output ?? "";
              // Parse space-separated list of container IDs
              const containerIds = output.trim().split(/\s+/).filter(s => s.length > 0);
              resolve(containerIds);
            } catch {
              resolve([]);
            }
          } else {
            resolve([]);
          }
        },
        onerror: () => resolve([]),
        ontimeout: () => resolve([]),
      });
    });
  }

  // ============================================================
  // XTERM ASSETS
  // ============================================================

  let xtermAssetsLoaded = false;

  function ensureXtermAssets() {
    if (xtermAssetsLoaded) return;
    const css = GM_getResourceText("XTERM_CSS");
    GM_addStyle(css);
    if (typeof Terminal !== "function" && typeof window.Terminal !== "function") {
      throw new Error("xterm Terminal is missing (check @require lines).");
    }
    xtermAssetsLoaded = true;
  }

  function getTerminalCtor() {
    return typeof Terminal === "function" ? Terminal : window.Terminal;
  }

  function getFitAddonCtor() {
    if (typeof FitAddon === "function") return FitAddon;
    if (window.FitAddon?.FitAddon) return window.FitAddon.FitAddon;
    if (typeof window.FitAddon === "function") return window.FitAddon;
    return null;
  }

  // ============================================================
  // MODAL UI (Channels DVR style - light theme)
  // ============================================================

  const MODAL_STYLE_ID = "tm-olivetin-modal-style";
  const MODAL_ROOT_ID = "tm-olivetin-modal-root";

  function injectModalStylesOnce() {
    if (document.getElementById(MODAL_STYLE_ID)) return;

    const css = `
      /* Reset any inherited styles that might interfere */
      #${MODAL_ROOT_ID}, #${MODAL_ROOT_ID} * {
        box-sizing: border-box;
      }

      #${MODAL_ROOT_ID} {
        position: fixed !important;
        top: 0 !important;
        left: 0 !important;
        right: 0 !important;
        bottom: 0 !important;
        z-index: 999999 !important;
        display: flex !important;
        align-items: flex-start;
        justify-content: center;
        padding-top: 40px;
      }

      #${MODAL_ROOT_ID} .tm-backdrop {
        position: absolute !important;
        top: 0 !important;
        left: 0 !important;
        right: 0 !important;
        bottom: 0 !important;
        background: rgba(0, 0, 0, 0.5);
      }

      #${MODAL_ROOT_ID} .tm-dialog {
        position: relative !important;
        width: min(980px, 95vw);
        max-height: 90vh;
        background: #fff;
        border-radius: 8px;
        box-shadow: 0 4px 24px rgba(0, 0, 0, 0.25);
        overflow: hidden;
        display: flex;
        flex-direction: column;
        font-family: system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        z-index: 1;
      }

      #${MODAL_ROOT_ID} .tm-header {
        display: flex;
        align-items: center;
        gap: 16px;
        padding: 20px 20px 16px;
        background: linear-gradient(to bottom, #f8f9fa, #fff);
        border-bottom: 1px solid #e5e5e5;
      }

      #${MODAL_ROOT_ID} .tm-header-icon {
        width: 64px;
        height: 64px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        overflow: hidden;
      }

      #${MODAL_ROOT_ID} .tm-header-icon img {
        width: 100%;
        height: 100%;
        object-fit: contain;
      }

      #${MODAL_ROOT_ID} .tm-header-text {
        flex: 1;
      }

      #${MODAL_ROOT_ID} .tm-title {
        font-size: 22px;
        font-weight: 600;
        color: #333;
        margin: 0 0 2px;
      }

      #${MODAL_ROOT_ID} .tm-subtitle {
        font-size: 13px;
        color: #888;
        margin: 0;
      }

      #${MODAL_ROOT_ID} .tm-close {
        position: absolute;
        top: 12px;
        right: 12px;
        background: transparent;
        border: none;
        color: #999;
        font-size: 28px;
        line-height: 1;
        cursor: pointer;
        padding: 4px 8px;
        border-radius: 4px;
      }
      #${MODAL_ROOT_ID} .tm-close:hover {
        color: #333;
        background: rgba(0, 0, 0, 0.05);
      }

      #${MODAL_ROOT_ID} .tm-body {
        padding: 20px;
        color: #333;
        font-size: 14px;
        overflow-y: auto;
      }

      #${MODAL_ROOT_ID} .tm-field {
        margin-bottom: 16px;
      }

      #${MODAL_ROOT_ID} .tm-label-row {
        display: flex;
        justify-content: space-between;
        align-items: baseline;
        margin-bottom: 6px;
      }

      #${MODAL_ROOT_ID} .tm-label {
        font-weight: 600;
        color: #333;
        font-size: 14px;
      }

      #${MODAL_ROOT_ID} .tm-description {
        font-size: 12px;
        color: #888;
        font-weight: 400;
      }

      #${MODAL_ROOT_ID} .tm-input,
      #${MODAL_ROOT_ID} .tm-select {
        width: 100%;
        box-sizing: border-box;
        background: #fff;
        color: #333;
        border: 1px solid #ccc;
        border-radius: 4px;
        padding: 10px 12px;
        font-size: 14px;
        outline: none;
        transition: border-color 0.15s, box-shadow 0.15s;
      }
      #${MODAL_ROOT_ID} .tm-input:focus,
      #${MODAL_ROOT_ID} .tm-select:focus {
        border-color: #4a90d9;
        box-shadow: 0 0 0 3px rgba(74, 144, 217, 0.15);
      }
      #${MODAL_ROOT_ID} .tm-input::placeholder {
        color: #999;
      }
      #${MODAL_ROOT_ID} .tm-select {
        cursor: pointer;
        appearance: none;
        background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%23666' d='M6 8L1 3h10z'/%3E%3C/svg%3E");
        background-repeat: no-repeat;
        background-position: right 12px center;
        padding-right: 36px;
      }

      #${MODAL_ROOT_ID} .tm-term-wrap {
        margin-top: 8px;
        background: #1e1e1e;
        border: 1px solid #ccc;
        border-radius: 6px;
        overflow: hidden;
        display: none;
      }

      #${MODAL_ROOT_ID} .tm-term-head {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px 12px;
        background: #2d2d2d;
        border-bottom: 1px solid #444;
        color: #ccc;
        font-size: 12px;
        font-weight: 500;
      }

      #${MODAL_ROOT_ID} .tm-term-status {
        color: #8BC34A;
      }

      #${MODAL_ROOT_ID} .tm-term {
        height: 280px;
        padding: 8px;
      }

      #${MODAL_ROOT_ID} .tm-footer {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 16px 20px;
        background: #f8f9fa;
        border-top: 1px solid #e5e5e5;
      }

      #${MODAL_ROOT_ID} .tm-footer-left {
        display: flex;
        gap: 8px;
      }

      #${MODAL_ROOT_ID} .tm-footer-right {
        display: flex;
        gap: 8px;
      }

      #${MODAL_ROOT_ID} .tm-btn {
        border-radius: 4px;
        padding: 10px 20px;
        border: none;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        transition: background-color 0.15s;
      }

      #${MODAL_ROOT_ID} .tm-btn-cancel {
        background: #e9e9e9;
        color: #333;
      }
      #${MODAL_ROOT_ID} .tm-btn-cancel:hover {
        background: #ddd;
      }

      #${MODAL_ROOT_ID} .tm-btn-run {
        background: #4CAF50;
        color: #fff;
      }
      #${MODAL_ROOT_ID} .tm-btn-run:hover {
        background: #43A047;
      }

      #${MODAL_ROOT_ID} .tm-btn:disabled {
        opacity: 0.6;
        cursor: not-allowed;
      }
    `;

    const style = document.createElement("style");
    style.id = MODAL_STYLE_ID;
    style.textContent = css;
    // Use appendChild for better cross-browser compatibility
    (document.head || document.documentElement).appendChild(style);
  }

  function closeModal() {
    document.getElementById(MODAL_ROOT_ID)?.remove();
  }

  function buildModal(action) {
    injectModalStylesOnce();
    closeModal();

    // Build input fields HTML for visible arguments only
    const visibleArgs = action.arguments.filter(arg => !arg.hidden);
    const fieldsHtml = visibleArgs.map(arg => {
      const labelHtml = `
        <div class="tm-label-row">
          <span class="tm-label">${arg.label || arg.name}</span>
          ${arg.description ? `<span class="tm-description">${arg.description}</span>` : ''}
        </div>
      `;

      // Check if this is a dropdown field (has options array)
      if (arg.options && Array.isArray(arg.options)) {
        const optionsHtml = arg.options.map(opt => {
          // Options can be { display: "Show This", value: "send_this" } or just a string
          const display = typeof opt === 'object' ? opt.display : opt;
          const value = typeof opt === 'object' ? opt.value : opt;
          return `<option value="${value}">${display}</option>`;
        }).join('');

        return `
          <div class="tm-field">
            ${labelHtml}
            <select class="tm-select" data-arg="${arg.name}" ${arg.optional ? '' : 'required'}>
              ${arg.placeholder ? `<option value="" disabled selected>${arg.placeholder}</option>` : ''}
              ${optionsHtml}
            </select>
          </div>
        `;
      }

      // Regular text input - use default as value if provided, otherwise placeholder as hint
      return `
        <div class="tm-field">
          ${labelHtml}
          <input
            class="tm-input"
            type="text"
            data-arg="${arg.name}"
            value="${arg.default || ''}"
            placeholder="${arg.placeholder || ''}"
            ${arg.optional ? '' : 'required'}
          />
        </div>
      `;
    }).join('');

    const root = document.createElement("div");
    root.id = MODAL_ROOT_ID;
    root.innerHTML = `
      <div class="tm-backdrop"></div>
      <div class="tm-dialog" role="dialog" aria-modal="true">
        <button class="tm-close" title="Close" aria-label="Close">&times;</button>

        <div class="tm-header">
          <div class="tm-header-icon">
            <img src="https://raw.githubusercontent.com/OliveTin/OliveTin/main/frontend/OliveTinLogo.png" alt="OliveTin" />
          </div>
          <div class="tm-header-text">
            <h2 class="tm-title">${action.title}</h2>
            <p class="tm-subtitle">OliveTin Action</p>
          </div>
        </div>

        <div class="tm-body">
          ${fieldsHtml}

          <div class="tm-term-wrap">
            <div class="tm-term-head">
              <span>Output</span>
              <span class="tm-term-status"></span>
            </div>
            <div class="tm-term"></div>
          </div>
        </div>

        <div class="tm-footer">
          <div class="tm-footer-left"></div>
          <div class="tm-footer-right">
            <button class="tm-btn tm-btn-cancel">Cancel</button>
            <button class="tm-btn tm-btn-run">Run</button>
          </div>
        </div>
      </div>
    `;

    // Append to body, ensuring it's at the end (highest stacking)
    document.body.appendChild(root);

    // Force the modal to be visible (workaround for some browser quirks)
    root.style.display = "flex";

    // Close behaviors
    root.querySelector(".tm-close").addEventListener("click", closeModal);
    root.querySelector(".tm-btn-cancel").addEventListener("click", closeModal);
    root.querySelector(".tm-backdrop").addEventListener("click", closeModal);

    const escHandler = (e) => {
      if (e.key === "Escape") {
        document.removeEventListener("keydown", escHandler, true);
        closeModal();
      }
    };
    document.addEventListener("keydown", escHandler, true);

    return root;
  }

  // ============================================================
  // DYNAMIC ACTION MODAL
  // ============================================================

  function openActionModal(action) {
    const root = buildModal(action);

    // Get all form fields (inputs and selects)
    const fields = root.querySelectorAll(".tm-input[data-arg], .tm-select[data-arg]");
    const runBtn = root.querySelector(".tm-btn-run");
    const wrap = root.querySelector(".tm-term-wrap");
    const termEl = root.querySelector(".tm-term");
    const statusEl = root.querySelector(".tm-term-status");

    let term = null;
    let fit = null;

    function ensureTerminal() {
      wrap.style.display = "block";
      ensureXtermAssets();

      if (!term) {
        const TerminalCtor = getTerminalCtor();
        term = new TerminalCtor({
          convertEol: true,
          scrollback: 5000,
          fontSize: 12,
          theme: { background: "#1e1e1e", foreground: "#d4d4d4" },
        });

        const FitCtor = getFitAddonCtor();
        if (FitCtor) {
          fit = new FitCtor();
          term.loadAddon(fit);
        }

        term.open(termEl);

        if (fit) {
          setTimeout(() => fit.fit(), 0);
          setTimeout(() => fit.fit(), 50);
          window.addEventListener("resize", () => fit.fit());
        }
      } else if (fit) {
        setTimeout(() => fit.fit(), 0);
        setTimeout(() => fit.fit(), 50);
      }

      return term;
    }

    async function onRun() {
      // Gather argument values
      const argValues = {};
      let hasError = false;

      // First, add hidden arguments
      action.arguments.forEach(arg => {
        if (arg.hidden && arg.value !== undefined) {
          argValues[arg.name] = arg.value;
        }
      });

      // Then gather visible field values (inputs and selects)
      fields.forEach(field => {
        const argName = field.dataset.arg;
        const argDef = action.arguments.find(a => a.name === argName);
        let value = field.value.trim();

        // Use default if field is empty and has a default defined
        if (!value && argDef?.default) {
          value = argDef.default;
        }

        if (!value && !argDef?.optional) {
          field.style.borderColor = "#e53935";
          setTimeout(() => (field.style.borderColor = "#ccc"), 900);
          hasError = true;
        } else {
          argValues[argName] = value;
        }
      });

      if (hasError) {
        fields[0]?.focus();
        return;
      }

      // Disable fields
      runBtn.disabled = true;
      fields.forEach(f => (f.disabled = true));

      const t = ensureTerminal();
      t.reset();
      statusEl.textContent = "Running...";

      try {
        // Build payload
        const payload = {
          actionId: action.id,
          arguments: Object.entries(argValues).map(([name, value]) => ({ name, value })),
        };

        // Show request info
        t.write(`\x1b[36mPOST ${OLIVETIN_BASE}/api/StartActionAndWait\x1b[0m\r\n`);
        t.write(`\x1b[90mAction: ${action.id}\x1b[0m\r\n`);
        Object.entries(argValues).forEach(([k, v]) => {
          t.write(`\x1b[90m  ${k}: ${v}\x1b[0m\r\n`);
        });
        t.write("\r\n");

        const raw = await gmPostJson(`${OLIVETIN_BASE}/api/StartActionAndWait`, payload);
        const obj = JSON.parse(raw);

        const output = obj?.logEntry?.output ?? null;
        const exitCode = obj?.logEntry?.exitCode;

        statusEl.textContent = `Done${typeof exitCode === "number" ? ` (exit ${exitCode})` : ""}`;

        if (output) {
          t.write(output.replace(/\r?\n/g, "\r\n") + "\r\n");
        } else {
          t.write("\x1b[33mNo output returned.\x1b[0m\r\n");
        }

        if (fit) {
          setTimeout(() => fit.fit(), 0);
          setTimeout(() => fit.fit(), 50);
        }
      } catch (e) {
        statusEl.textContent = "Error";
        t.write(`\r\n\x1b[31mERROR: ${String(e)}\x1b[0m\r\n`);
      } finally {
        runBtn.disabled = false;
        fields.forEach(f => (f.disabled = false));
      }
    }

    runBtn.addEventListener("click", onRun);
    fields.forEach(field => {
      field.addEventListener("keydown", (e) => {
        if (e.key === "Enter") onRun();
      });
    });

    // Focus first input
    fields[0]?.focus();
  }

  // ============================================================
  // NAVBAR MENU INJECTION
  // ============================================================

  function menuIsOpen(wrapper, menu) {
    return wrapper.classList.contains("show") || menu.classList.contains("show");
  }

  function menuSetOpen(wrapper, toggle, menu, open) {
    wrapper.classList.toggle("show", open);
    menu.classList.toggle("show", open);
    toggle.setAttribute("aria-expanded", String(open));
  }

  function closeAllExcept(exceptWrapperId) {
    // Close ALL dropdowns (both native and custom) except the one being opened
    document.querySelectorAll(".nav-item.dropdown").forEach(w => {
      const m = w.querySelector(":scope > .dropdown-menu");
      const t = w.querySelector(":scope > .nav-link.dropdown-toggle");
      if (!m || !t) return;
      if (w.id === exceptWrapperId) return;
      // Close any open dropdown
      w.classList.remove("show");
      m.classList.remove("show");
      t.setAttribute("aria-expanded", "false");
    });
  }

  function injectOliveTinDropdown(navRow, settingsItem) {
    if (document.getElementById(NAV_ITEM_ID)) return true;

    const wrapper = document.createElement("div");
    wrapper.id = NAV_ITEM_ID;
    wrapper.className = "nav-item dropdown";
    wrapper.dataset.tmDropdown = "1";

    const toggle = document.createElement("a");
    toggle.id = TOGGLE_ID;
    toggle.href = "#";
    toggle.className = "dropdown-toggle nav-link";
    toggle.setAttribute("role", "button");
    toggle.setAttribute("aria-haspopup", "true");
    toggle.setAttribute("aria-expanded", "false");

    toggle.innerHTML = `<svg aria-hidden="true" focusable="false" class="svg-inline--fa fa-code fa-w-20 mr-1" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 512"><path fill="currentColor" d="M392.8 1.2c-17-4.9-34.7 5-39.6 22l-128 448c-4.9 17 5 34.7 22 39.6s34.7-5 39.6-22l128-448c4.9-17-5-34.7-22-39.6zm80.6 120.1c-12.5 12.5-12.5 32.8 0 45.3L562.7 256l-89.4 89.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0l112-112c12.5-12.5 12.5-32.8 0-45.3l-112-112c-12.5-12.5-32.8-12.5-45.3 0zm-306.7 0c-12.5-12.5-32.8-12.5-45.3 0l-112 112c-12.5 12.5-12.5 32.8 0 45.3l112 112c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L77.3 256l89.4-89.4c12.5-12.5 12.5-32.8 0-45.3z"/></svg><span>OliveTin</span>`;

    const menu = document.createElement("div");
    menu.id = MENU_ID;
    menu.className = "dropdown-menu";
    menu.setAttribute("aria-labelledby", TOGGLE_ID);
    menu.style.margin = "0px";

    // Add header descriptor
    const header = document.createElement("h6");
    header.className = "dropdown-header";
    header.style.fontSize = "inherit";
    header.textContent = "Run Action:";
    menu.appendChild(header);

    // Add divider line
    const divider = document.createElement("div");
    divider.className = "dropdown-divider";
    menu.appendChild(divider);

    // Build menu items from ACTIONS config
    for (const action of ACTIONS) {
      const item = document.createElement("a");
      item.className = "dropdown-item";
      item.dataset.actionId = action.id; // Store action ID for green icon lookup
      item.textContent = action.label;
      item.href = "#";

      item.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        menuSetOpen(wrapper, toggle, menu, false);
        openActionModal(action);
      });

      menu.appendChild(item);
    }

    toggle.addEventListener("click", async (e) => {
      e.preventDefault();
      e.stopPropagation();
      const wasOpen = menuIsOpen(wrapper, menu);
      closeAllExcept(wrapper.id);

      if (!wasOpen) {
        // Fetch green icons and update menu before opening
        const greenIds = await fetchGreenIcons();
        updateMenuGreenIndicators(menu, greenIds);
      }

      menuSetOpen(wrapper, toggle, menu, !wasOpen);
    });

    document.addEventListener("click", (e) => {
      if (!menuIsOpen(wrapper, menu)) return;
      if (wrapper.contains(e.target)) return;
      menuSetOpen(wrapper, toggle, menu, false);
    }, { capture: true });

    wrapper.appendChild(toggle);
    wrapper.appendChild(menu);

    if (settingsItem?.parentElement === navRow) {
      settingsItem.after(wrapper);
    } else {
      navRow.appendChild(wrapper);
    }

    return wrapper;
  }

  function injectOneClickDropdown(navRow, afterElement) {
    if (document.getElementById(ONECLICK_NAV_ITEM_ID)) return true;

    const wrapper = document.createElement("div");
    wrapper.id = ONECLICK_NAV_ITEM_ID;
    wrapper.className = "nav-item dropdown";
    wrapper.dataset.tmDropdown = "1";

    const toggle = document.createElement("a");
    toggle.id = ONECLICK_TOGGLE_ID;
    toggle.href = "#";
    toggle.className = "dropdown-toggle nav-link";
    toggle.setAttribute("role", "button");
    toggle.setAttribute("aria-haspopup", "true");
    toggle.setAttribute("aria-expanded", "false");

    // fa-arrow-pointer icon (cursor/pointer icon)
    toggle.innerHTML = `<svg aria-hidden="true" focusable="false" class="svg-inline--fa fa-arrow-pointer fa-w-20 mr-1" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512"><path fill="currentColor" d="M0 55.2V426c0 12.2 9.9 22 22 22c6.3 0 12.4-2.7 16.6-7.5L121.2 346l58.1 116.3c7.9 15.8 27.1 22.2 42.9 14.3s22.2-27.1 14.3-42.9L179.8 320H297c12.1 0 21.7-9 23-21.1c.2-1.2 .3-2.5 .3-3.9c0-7.5-3.1-14.7-8.5-19.8L68 34.7c-4.5-4.5-10.5-7-16.9-7C23.7 27.7 0 44.8 0 55.2z"/></svg><span>One-Click</span>`;

    const menu = document.createElement("div");
    menu.id = ONECLICK_MENU_ID;
    menu.className = "dropdown-menu";
    menu.setAttribute("aria-labelledby", ONECLICK_TOGGLE_ID);
    menu.style.margin = "0px";

    // Add header descriptor
    const header = document.createElement("h6");
    header.className = "dropdown-header";
    header.style.fontSize = "inherit";
    header.textContent = "Install Project:";
    menu.appendChild(header);

    // Add divider line
    const divider = document.createElement("div");
    divider.className = "dropdown-divider";
    menu.appendChild(divider);

    // Build menu items from ONE_CLICK_ACTIONS config
    for (const action of ONE_CLICK_ACTIONS) {
      const item = document.createElement("a");
      item.className = "dropdown-item";
      item.dataset.actionId = action.id; // Store action ID for running container lookup
      item.textContent = action.label;
      item.href = "#";

      item.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        menuSetOpen(wrapper, toggle, menu, false);
        openActionModal(action);
      });

      menu.appendChild(item);
    }

    toggle.addEventListener("click", async (e) => {
      e.preventDefault();
      e.stopPropagation();
      const wasOpen = menuIsOpen(wrapper, menu);
      closeAllExcept(wrapper.id);

      if (!wasOpen) {
        // Fetch running containers and update menu before opening
        const containerIds = await fetchRunningContainers();
        updateMenuGreenIndicators(menu, containerIds);
      }

      menuSetOpen(wrapper, toggle, menu, !wasOpen);
    });

    document.addEventListener("click", (e) => {
      if (!menuIsOpen(wrapper, menu)) return;
      if (wrapper.contains(e.target)) return;
      menuSetOpen(wrapper, toggle, menu, false);
    }, { capture: true });

    wrapper.appendChild(toggle);
    wrapper.appendChild(menu);

    if (afterElement?.parentElement === navRow) {
      afterElement.after(wrapper);
    } else {
      navRow.appendChild(wrapper);
    }

    return true;
  }

  function injectNavbarDropdowns() {
    if (document.getElementById(NAV_ITEM_ID) && document.getElementById(ONECLICK_NAV_ITEM_ID)) return true;

    const navRow = document.querySelector("nav.navbar .navbar-collapse .navbar-nav");
    if (!navRow) return false;

    const settingsItem = document.querySelector("#settings-nav-dropdown")?.closest(".nav-item");

    // Inject OliveTin dropdown first (after settings)
    const oliveTinWrapper = injectOliveTinDropdown(navRow, settingsItem);

    // Inject One-Click dropdown after OliveTin
    injectOneClickDropdown(navRow, oliveTinWrapper || settingsItem);

    return true;
  }

  // Initial injection + SPA-safe retries
  if (injectNavbarDropdowns()) return;

  const obs = new MutationObserver(() => injectNavbarDropdowns());
  obs.observe(document.documentElement, { childList: true, subtree: true });
  setTimeout(() => obs.disconnect(), 60000);
})();
