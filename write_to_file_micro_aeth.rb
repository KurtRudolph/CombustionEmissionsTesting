#!/usr/bin/env ruby
require_relative 'micro_aeth.rb'

com = MicroAeth::Com.new
com.start
file_name = '/home/pi/Desktop/LiveGraphData/' + Time.now.to_s + '.micro_aeth.dat'
f = File.new file_name, 'w'
f << %w(Timedate Ref Sen ATN Flow Temp Status Battery sigma_ap).join(',') + "\n"
f.close

com.start_write_to_file file_name

begin
  print "\nType 'exit' to stop program: "
end while gets != "exit\n"

puts "\nStopping writes to #{f.path}"
com.stop_write_to_file
