require 'serialport'

module DAQ
  class Com
    attr_accessor :com, :messages
    attr_reader :com_thread

    def initialize
      port     = '/dev/ttyUSB1'
      baud     = 9600
      bytesize = 8
      stopbits = 1
      parity   = SerialPort::NONE
      @com     = SerialPort.new port, baud, bytesize, stopbits, parity
      @messages = []
    end

    ##
    # @return A ruby thread which continually reads
    #   from the MicroAeth::Com#com instance
    def read
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
