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