require 'httparty'
require 'json'

server_url = ENV["CHANNELS_DVR"]
video_group = ARGV[0]

source_files = HTTParty.get("http://#{server_url}/dvr/groups/#{video_group}/files")

source_files.each do |file|
  file_id = file['ID']
  title = file['Airing']['EpisodeTitle']
  yt_match = title.match(/(_\((\d\d\d\d-\d\d-\d\d)\))?_?\[(.*)\]/)

  if yt_match
    yt_date = yt_match[2]
    yt_id = yt_match[3]
    yt_thumbnail_url = "https://i3.ytimg.com/vi/#{yt_id}/maxresdefault.jpg"
    new_title = title.gsub(yt_match[0], '')

    package = {Thumbnail: yt_thumbnail_url, Airing: {EpisodeTitle: new_title}}

    if yt_date
      package[:Airing][:OriginalDate] = yt_date
    end

    HTTParty.put("http://#{server_url}/dvr/files/#{file_id}", :body => package.to_json)
  end
end