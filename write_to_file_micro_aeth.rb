require_relative 'micro_aeth.rb'

com = MicroAeth::Com.new
daq.start

f = File.new ('tmp/' + Time.now.to_s + '.micro_aeth.dat'), 'w'
f << %w(Ref Sen ATN Flow Temp Status Battery sigma_ap).join(',') + "\n"
daq.start_write_to_file f

require 'pry'
begin
  print "\nType 'exit' to stop program: "
end while gets != "exit\n"

puts "\nStopping writes to #{f.path}"
com.stop_write_to_file
