require_relative 'daq.rb'


daq = DAQ::Com.new
daq.start

f = File.new 'tmp/daq.dat', 'a+'
f << daq.column_names.join(',') + "\n"
while true
  f << daq.com.realine
end
