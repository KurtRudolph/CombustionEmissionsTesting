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
    attr_accessor :com, :messages
    attr_reader :com_thread

    def initialize
      port     = 'usb-Prolific_Technology_Inc._USB-Serial_Controller_D-if00-port0'
      baud     = 9600
      bytesize = 8
      stopbits = 1
      parity   = SerialPort::NONE
      @com     = SerialPort.new port, baud, bytesize, stopbits, parity
      @messages = []
    end
    

    ##
    # Assumes the device is already running
    # @return A ruby thread which continually reads
    #   from the MicroAeth::Com#com instance
    # @collumn_names The names of each of the readings
    # @cals The calibration constants
    def read collumn_names, cals
      @columns = collumn_names.split(',')
      @collumns[-1] = (@columns[-1])[0..-3] # all but the last two characters
      @com_thread = Thread.new do
        begin
          while true
            @messages << @com.readline
          end
        # Intermitently, it the serialport library raises end of file...
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
