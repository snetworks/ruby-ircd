require 'optparse'

OptionParser.new do |opts|
  opts.banner = 'Usage: serv [options]'

  opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
    ARG_VERBOSE = v
  end
  
  opts.on('-r', '--[no-]raw', 'Show raw traffic') do |r|
    ARG_RAW = r
  end
  
  opts.on('-c', '--[no-]color', 'Color output') do |c|
    ARG_COLOR = c
  end
  
  opts.on('-f', '--file CFG_FILE', 'Set config file (default is cfg.xml)') do |f|
    ARG_CFG_FILE = f
  end
end.parse!
