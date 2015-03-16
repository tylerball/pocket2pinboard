require "rubygems"
require "bundler/setup"
Bundler.require
require "erb"
require 'pinboard'
require 'nokogiri'

filename = ""

config = YAML.load_file('config.yml')
pinboard = Pinboard::Client.new(token: config['token'])

filename = ARGV[0] if ARGV.size == 1
if File.exists? filename then
  data = Nokogiri::HTML(File.read(filename))
  links = data.css("a")
  links.each_with_index do |link, index|
    progress = "[#{index + 1}/#{links.length}]"
    begin
      title = link.text
      defaulttags = config['defaulttags'].join(',')
      tags = link['tags'].length > 0 ? "#{link['tags']},#{defaulttags}" : defaulttags
      toread = link.parent.parent.previous_element.text == 'Unread' ? true : false
      if link['href'] == link.text
        title = Nokogiri.parse(HTTParty.get(link['href'])).css('title').text
      end

      pinboard.add({
        url: link['href'],
        description: title,
        tags: tags,
        dt: DateTime.strptime(link['time_added'],'%s'),
        shared: !toread,
        toread: toread,
        replace: true
      })
      puts "#{progress} adding #{link['href']}"
    rescue Pinboard::Error
      puts "#{progress} error: #{link['href']}"
    end
  end
else
  puts "please supply a valid input file"
end
