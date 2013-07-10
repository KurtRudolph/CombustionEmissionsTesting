#!/usr/bin/env ruby
require_relative 'daq.rb'

daq = DAQ.new
daq.start

file_name = '/home/pi/Desktop/LiveGraphData/' + Time.now.to_s + '.daq.dat'
f = File.new file_name, 'w'
f << "DateTime," + daq.column_names.join(',') + "\n"
f.close
daq.start_write_to_file file_name

begin
  print "\nType 'exit' to stop program: "
end while gets != "exit\n"

puts "\nStopping writes to #{f.path}"
daq.stop_write_to_file
