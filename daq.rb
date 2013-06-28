require 'serialport'

module DAQ
  def start
    com = Com.new
    com.com.write "log\r"
    5.times do
      com.messages << com.com.readline
    end
    
  end
  class Com
    attr_accessor :com, :messages, :cal_consts, :column_names
    attr_reader :com_thread

    def initialize
      port     = '/dev/serial/by-id/usb-Prolific_Technology_Inc._USB-Serial_Controller_D-if00-port0'
      baud     = 9600
      bytesize = 8
      stopbits = 1
      parity   = SerialPort::NONE
      @com     = SerialPort.new port, baud, bytesize, stopbits, parity
      @messages = []
    end
    def start
      begin 
        while true
          @com.readchar
        end
      rescue EOFError
        sleep 1
      end
      @com.write "log\r"
      3.times { sleep 1; @com.readline }
      @cal_consts = @com.readline.split(',')
      @cal_consts[-1] = (@cal_consts[-1])[0..-3]
      @column_names = @com.readline.split(',')
      @column_names[-1] = (@column_names[-1])[0..-3]
      read
    end

    ##
    # Assumes the device is already running
    # @return A ruby thread which continually reads
    #   from the MicroAeth::Com#com instance
    # @collumn_names The names of each of the readings
    # @cals The calibration constants
    def read
      @com_thread = Thread.new do
        begin
          while true
            line = @com.readline.split(',')
            line[-1] = (line[-1])[0..-3]
            @messages << line
          end
        rescue EOFError
          sleep 1
          retry
        end 
      end
    end

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
