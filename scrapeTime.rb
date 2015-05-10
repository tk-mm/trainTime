# coding: utf-8
require 'rubygems'
require 'twitter'
require 'nokogiri'
require 'open-uri'

C_KEY = 'zgfdFHTvcCd3dZnRpWGqh7vA2'
C_SECRET = 'KB0bomQ3ejxtOMlzn4gK8sAEYsuA9iDxTRky3uT1H8wL3xKXRV'
A_TOKEN = '1015317498-pTB9nPZ6iWBnoacva0D715l9UfTQbzRh4Dz31jo'
A_T_SECRET = 'ecEbeQIwk4N5ZubtKs08puxXoiJAWA2jsW2H7cPrWCdzX'

client = Twitter::REST::Client.new do |config|
  config.consumer_key = C_KEY
  config.consumer_secret = C_SECRET
  config.access_token = A_TOKEN
  config.access_token_secret = A_T_SECRET
end

stream_client = Twitter::Streaming::Client.new do |config|
  config.consumer_key = C_KEY
  config.consumer_secret = C_SECRET
  config.access_token = A_TOKEN
  config.access_token_secret = A_T_SECRET
end                                           

# 現在時からその時間帯の電車を表示
def data(date, time)
  url = case date.to_i
        when 0 then
          # holiday
          'http://transit.loco.yahoo.co.jp/station/time/22630/?kind=4&gid=3320&tab=time&done=time'
        when 1..5 then
          # weekday
          "http://transit.loco.yahoo.co.jp/station/time/22630/?kind=1&gid=3320&tab=time&done=time"
        when 6 then
          # saturday
          'http://transit.loco.yahoo.co.jp/tation/time/22630/?kind=2&gid=3320&tab=time&done=time'
        end
  charset = nil
  html = open(url) do |f|
    charset = f.charset
    f.read
  end
  doc = Nokogiri::HTML.parse(html, nil, charset)                                                
  tds = doc.xpath("//td")
  tmp = []
  tds.each_with_index do |v, index|
    if v.text == time && "" != tds[index + 1].text.gsub(" ","")
      tmp << tds[index + 1].text.split("\n").map(&:to_s)
    end
  end
  tmp[0].uniq!
  text = ""
  tmp[0].each do |v|
    text << v + ', '
  end
  text.slice!(text.length-2, text.length)
  text.slice!(0..1)
  return text
end

stream_client.user do |status|
  next unless status.is_a? Twitter::Tweet
  next if status.text.start_with? "RT"
  if status.text =~ /^@hyuz_帰る$/
    t = Time.now
    date = t.strftime("%w")
    time = t.strftime("%H")
    option = {"in_reply_to_status_id" => status.id.to_s }
    tweet = "@#{status.user.screen_name} #{time}時: #{data(date, time)}"
    client.update tweet, option
  end                     
end
