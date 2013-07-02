require_relative 'daq.rb'


daq = DAQ::Com.new
daq.start

f = File.new 'temp/daq.dat', 'a+'
f << daq.column_names.join(',') + "\n"
f << daq.com.realine
