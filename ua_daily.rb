require 'ltsv'
require 'useragent'
require 'zlib'
ALL = '19700101'

def show
  print "useragent@#{$date}/#{$count},100%,#{$hash.keys.sort.join(',')}\n"
  $hash[ALL].keys.sort{|a, b| $hash[ALL][a] <=> $hash[ALL][b]}.reverse.each {|key|
    percent = $hash[ALL][key] * 100.0 / $count
    next if percent < 0.01
    print ([key, "#{sprintf('%.2f', percent)}%"] + $hash.keys.sort.map{|date| $hash[date][key]}).join(','), "\n"
  }
  print "ALL#{' ' * 21},100%,#{$hash.keys.sort.map{|date| $hash[date].values.inject{|sum, n| sum + n}}.join(',')}\n\n"
end

def process(l)
  r = LTSV.parse(l)[0]
  return if r[:origin] == 'true'
  return unless r[:req].start_with?('GET /xyz/')
  $count += 1
  ua = UserAgent.parse(r[:ua])
  key = (ua.browser == 'Internet Explorer') ?
    "#{ua.browser}/#{ua.version}" :
    "#{ua.browser}/#{ua.platform}"
  key.chop! if key.end_with?('/')
  key = sprintf("%-24s", key)
  $hash[ALL][key] += 1
  $hash[$date][key] += 1
  show if $count % 50000 == 0
end

$count = 0
$hash = Hash.new{|h, k| h[k] = Hash.new{|h, k| h[k] = 0}}
Dir.glob("/Volumes/cyberjapandata/logs/*.ltsv.gz").sort.each {|f|
  $date = f.split('/')[-1].split('.')[0]
  Zlib::GzipReader.open(f) {|r|
    r.each {|l|
      process(l)
    }
  }
}
show
