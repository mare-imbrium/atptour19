#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: parse_results.rb
#  Description: Parse the scores downloaded from atptour.com
#       Author:  r kumar
#         Date: 2019-02-01 - 10:07
#  Last update: 2019-02-03 00:14
#      License: MIT License
# ----------------------------------------------------------------------------- #
#
require 'nokogiri'
require 'pp'
require "yaml"
require 'json'
    # h = JSON.parse(str)
require 'sqlite3'
# get_first_value  get_first_row
# http://www.rubydoc.info/github/luislavena/sqlite3-ruby/SQLite3/Database
require 'color' # see ~/work/projects/common/color.rb
  # print color("Hello there black reverse on yellow\n", "black", "on_yellow", "reverse")

# --- some common stuff ---
#today = Date.today.to_s
#now = Time.now.to_s
# include? exist? each_pair split gsub

def loadYML( filename)
  hash = YAML::load( File.open( filename ) )
  if $opt_debug
    $stderr.puts hash.keys.size
  end
  return hash
end
def writeYML obj, filename
  File.open(filename, 'w') {|f| f.write obj.to_yaml }
  if $opt_debug
    $stderr.puts "Written to file #{filename}"
  end
end

# abbreviate round to F/SF/QF
def _abbreviate lev
  lev = lev.downcase
  str = 
  case lev
  when "final"
    "F"
  when "semifinals"
    "SF"
  when "quarterfinals"
    "QF"
  else
    if lev.index("round of")
      "R" + lev.split(" ").last
    elsif lev.index("qualifying")
      "Q" + lev[0]
    else
      "???"
    end
  end
end


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  process_year
#   DESCRIPTION:  parse downloaded files for the given year
#    PARAMETERS:  Integer year
#       RETURNS:  nil
#-------------------------------------------------------------------------------
def process_year year
  #
  # Convert incoming html files to csv or json files
  path  = "in/#{year}/results"
  files =  Dir.glob("#{path}/*")
  $stderr.puts "infiles: #{files.size}"
  exit if files.size < 1
  outpath = path.sub("in", "out")

  # select files that do not have tsv counterpart
  outnames = Hash.new
  todolist = files.select {|v| 
    name = File.basename(v, ".html")
    oname = "#{outpath}/#{name}.tsv"
    outnames[v] = oname
    #$stderr.puts oname
    !File.exist? oname
  }
  $stderr.puts "todo list"
  $stderr.puts todolist.size
  exit(1) if todolist.size == 0
  #pp todolist
  todolist.each_with_index do |e, ix|
    main, fullarray = _parse_html e
    puts "Calling print_match with #{outnames[e]}"
    print_match outnames[e], fullarray
    append_event main
    #print_match "tmp.#{ix}", fullarray
  end
end
def _parse_html filename
  sep = '/'
  osep = "\t"
  osep = "|"
  infile = open(filename)
  doc = Nokogiri::HTML(infile.read)
  #
  # First the event level data such as dates, name, prize money, court, surface, commitment
  # second the result of each match as a line-item
  main = Hash.new
  year = filename.split(sep)[1] 
  code = filename.split(sep).last.sub(".html","").split('-').last
  event_code = "#{year}-#{code}"
  main[:event_code] = event_code
  daterange = doc.css("td.title-content span.tourney-dates").text.strip
  dates = daterange.split("-")
  main[:start_date] = dates.first.strip
  main[:end_date]   = dates.last.strip
  court = doc.css("td.tourney-details div.info-area div.item-details span.item-value")[2].text.strip
  main[:court] = court
  draw = doc.css("td.tourney-details div.info-area div.item-details span.item-value")[0].text.strip
  main[:draw] = draw
  location = doc.css("td.title-content span.tourney-location").text.strip
  main[:location] = location
  main[:title] = doc.css("title").text.strip.split("|").first.strip
  #puts filename
  #pp main
  $stderr.puts ">>> #{event_code}"
  #trs = doc.css("div.day-table-wrapper table.day-table tbody tr")
  s = doc.css("div#scoresResultsContent")
  theads=s.css("thead")
  tbodys=s.css("tbody")

  counter = 0
  fullarray = Array.new
  tbodys.each_with_index do |tbody, iix|
    #$stderr.puts theads[iix].css("th").text
    levelstr = _abbreviate(theads[iix].css("th").text)
    # TODO to get the round we need to check tbody and the th
    tbody.css("tr").each_with_index do |tr, trix|
      w = Hash.new
      w[:seed] = tr.css("td.day-table-seed")[0].text.strip
      link =  tr.css("td.day-table-name a").attribute("href").text
      w[:code] = link.split(sep)[-2]
      w[:name] =  tr.css("td.day-table-name a").first.text
      #puts tr.css("td.day-table-flag img").attribute("src").text
      flag =  tr.css("td.day-table-flag img")[0].attribute("src").text
      w[:country] =  flag.split(sep).last[0..2].upcase
      l = Hash.new
      l[:seed] =  tr.css("td.day-table-seed")[1].text.strip
      link =  tr.css("td.day-table-name a")[1].attribute("href").text
      l[:code] =  link.split(sep)[-2]
      l[:name] =  tr.css("td.day-table-name a")[1].text
      flag =  tr.css("td.day-table-flag img")[1].attribute("src").text
      l[:country] =  flag.split(sep).last[0..2].upcase
      score =  tr.css("td.day-table-score").text.strip
      stats =  tr.css("td.day-table-score a").attribute("href").text.strip rescue nil
      level =  levelstr
      match_code = "XXX"
      if stats 
        match_code = stats.split("/")[-2]
      else
        match_code = "NOSTATS"
      end
      w[:seed] = "-" if w[:seed] == ""
      l[:seed] = "-" if l[:seed] == ""
      w[:code] = "-" if w[:code] == ""
      l[:code] = "-" if l[:code] == ""
      num = counter + 1
      counter += 1
      #puts stats
      arr = Array.new
      arr << [ event_code, num, w.values, l.values, score, level, match_code ].flatten
      fullarray << arr
      #print "#{event_code}#{osep}#{num}#{osep}"
      #print w.values.join(osep)
      #print osep
      #print l.values.join(osep)
      #print osep
      #puts [score, level, match_code].join(osep)

    end # rows
  end
  return main, fullarray
end
def print_match outname, fullarray
  osep = "\t"
  puts "Writing to #{outname}"
  File.open(outname, 'w') {|f| 
    fullarray.each do |row|
      f.puts row.join(osep)
    end
  }
end
def append_event main
  # ::TRICKY:: 2019-02-03 - 00:08 - I am appending to a file, what if already a row for that event ?
  ##  maybe i should read into array, and then insert only if not present and then write array back
  osep = "\t"
  outname = "events.tsv"
  $stderr.puts "Writing to #{outname}"
  File.open(outname, 'a') {|f| 
    f.puts main.values.join(osep)
  }
  $stderr.puts "Written to #{outname}"
end


  if __FILE__ == $0
    include Color
    $opt_verbose = false
    $opt_debug = false
    $opt_quiet = false
    begin
      # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
      require 'optparse'
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options]"

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          options[:verbose] = v
          $opt_verbose = v
        end
        opts.on("--debug", "Show debug info") do 
          options[:debug] = true
          $opt_debug = true
        end
        opts.on("-q", "--quiet", "Run quietly") do |v|
          $opt_quiet = true
        end
      end.parse!

      p options if $opt_debug
      p ARGV if $opt_debug

      year = ARGV.first
      process_year year

    ensure
    end
  end

