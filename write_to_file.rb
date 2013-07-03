require_relative 'daq.rb'

daq = DAQ.new
daq.start

f = File.new (Time.now.to_s + '.daq.dat'), 'a+'
daq.start_write_to_file f

require 'pry'
begin
  print "\nType 'exit' to stop program: "
end while gets != "exit\n"

puts "\nStopping writes to #{f.path}"
daq.stop_write_to_file
