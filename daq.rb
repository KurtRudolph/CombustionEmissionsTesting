require 'serialport'
require 'timeout'

class DAQ
  attr_accessor :com, :messages, :cal_consts, :column_names
  attr_reader :thread

  def initialize
    port     = '/dev/ttyAMA0'
    baud     = 9600
    bytesize = 8
    stopbits = 1
    parity   = SerialPort::NONE
    @com     = SerialPort.new port, baud, bytesize, stopbits, parity
    @com.read_timeout = 5000
    @messages = []
  end

  def start
    begin 
      begin 
        Timeout::timeout 60 do
          while true
            puts @com.readchar
          end
        end
      rescue Timeout::Error
        raise 'DAQ already running'
      end 
    rescue EOFError
      nil
    end
    @com.write "log\r"
    3.times { sleep 3; @com.readline }
    sleep 3
    @cal_consts = @com.readline[1..-3].split(',')
    @cal_consts = @cal_consts.map { |const| const.to_f }
    sleep 3
    @column_names = @com.readline[0..-3].split(',')
    i=0; @cal_consts[i] = 1.0 if i = @column_names.find_index('seconds')
    self
  end

  ##
  # Assumes the device is already running
  # @collumn_names The names of each of the readings
  # @cals The calibration constants
  def read
    @thread = Thread.new do
      begin
        while true
          line = @com.readline[0..-3].split(',')
          @messages << line
        end
      rescue EOFError
        sleep 3
        retry
      end 
    end
  end
  def read_message
    m = @com.readline[0..-3].split(',')
    raise Error if @cal_consts.size != m.size
    m.each_index {|i| m[i] = m[i].to_f * @cal_consts[i]}
    m
  end
  ###
  # @file a ruby file object
  def start_write_to_file file_name
    @stop_writing_to_file = false
    @thread = Thread.new do
      while @stop_writing_to_file != true
        file = File.new file_name, 'a'
        message = read_message.join(',') + "\n"
        file << message
        file.close
      end
    end
  end
  def stop_write_to_file
    @stop_writing_to_file = true
    @thread.join 30
  end
end

=begin
2.0.0 (main):0 > com.com.write "log\r"
=> 4
2.0.0 (main):0 > com.com.readline
=> "log\r\n"
2.0.0 (main):0 > com.com.readline
=> "#logging\r\n"
2.0.0 (main):0 > com.com.readline
=> "##,## \r\n"
2.0.0 (main):0 > com.com.readline
=> "#0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1\r\n"
2.0.0 (main):0 > com.com.readline
=> "seconds,PMred,PMir,Tflow,Qflow,CO,CObkg,Aflow,TC,bat1,bat2,temp1,temp2,CO2,CO2bkg,RH,PMtemp\r\n"
2.0.0 (main):0 > com.com.readline
=> "1.00,131071,131071,0,38838,38973,39158,131071,131071,131071,131071,131071,131071,131071,131071,131071,131071\r\n"
2.0.0 (main):0 > com.com.readline
=> "4.00,131071,131071,-1,44691,46573,45088,131071,131071,131071,131071,131071,131071,131071,131071,131071,131071\r\n"
2.0.0 (main):0 > com.com.readline
=> "7.00,131071,131071,-1,49932,53661,50459,131071,131071,131071,131071,131071,131071,131071,131071,131071,131071\r\n"
=end
