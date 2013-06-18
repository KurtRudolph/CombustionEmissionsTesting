require 'serialport'

module MicroAeth
  ###
  # Creates and parses messages to and from the MicroAeth.
  # See MicroAeth::Com for specifications on the
  # transmiting of messages.
  class Message
    attr :original_char_string,
         :ref,
         :sen1,
         :sen2,
         :flow,
         :pcb_temp,
         :time,
         :status,
         :battery

    ##
    # @param data [String] conents between the `STX` "\x02"
    #   and the `ETX` "0x03"
    def initialize data
      binding.pry
      raise "invalid data" unless validate_data data
      data
      @original_char_string = data
      read_data( data[7..-1])
    end

    private
      def data_validate? d
        crc = d[-1].bytes[0]
        data = d[1...-1].bytes
        len = d[0].bytes[0]
        (xor data, len) == crc
      end
      # The xor of two byte strings 
      # @arg str_arg a one byte string
      # @self data string
      def xor str0, str1
        str0.each do |i|
          str1 = str1 ^ i
        end
        str1
      end
      def read_data d
        b = d.bytes
        @ref = d[0..2].unpack("v")[0]
        @sen1 = d[3..5].unpack("v")[0]
        @sen2 = d[6..8].unpack("v")[0]
        @flow = d[9..10].unpack("v")[0]
        @pcb_temp = b[11]
        @time = Time.new ('20' + b[12].to_s).to_i,
                         b[13],
                         b[14],
                         b[15],
                         b[16],
                         b[17]
        @status = b[18]
        @battery = d[19..20].unpack("v")[0]
      end

  end


  ##
  # Initializes a link between the the system and the device.
  # used to transmit and recieive MicroAeth::Message
  # 
  class Com
    attr_accessor :com, :messages
    attr_reader :com_thread


    def initialize
      port     = '/dev/ttyUSB0'
      baud     = 500_000
      bytesize = 8
      stopbits = 1
      parity   = SerialPort::MARK
      @com     = SerialPort.new port, baud, bytesize, stopbits, parity
      @messages = []
    end

    ##
    # @return A ruby thread which continually reads
    #   from the MicroAeth::Com#com instance
    def read_com
      @com_thread = Thread.new do
        com = MicroAeth::Com.new.com
        begin
          while true
            while @com.readchar != "\x02"; nil; end
            message = ''
            while (c = @com.readchar) != "\x03"
              message = message + c
            end
            @messages.push message
          end
        rescue EOFError
          sleep 1
          retry
        end 
      end
    end
       
  
#EOFError: end of file reached
#from (pry):13:in `readbyte`
#def something
  #com = MicroAeth::Com.new.com
  #begin
    #while 1
      #puts com.readbyte
    #end
  #rescue EOFError
    #sleep 1
    #retry
  #end
#end

    def read_message
      message = ''
      while @com.readchar != "\x02"
        nil
      end
      while (c = @com.readchar) != "\x03"
        message = message + c
      end
      Message.new message
    end
  end
end

=begin
You'll need to assemble a properly formed message, or it won't respond.   
## Properly forming a messages as suggested by Karl Walter

Communication protocol is based on folowing syntax: 
`STX LEN DATA CRC ETX`  where:

* `STX` is one byte 0x02 (HEX values)
* `LEN` is one byte lenght of `DATA` 
* `CRC` is XOR function between `LEN` byte and `DATA` bytes 
  * I'm assuming this is the last byte of data
* `ETX` is one byte 0x03

Every string of `DATA` that microAethCOM PC 
software sends starts with `AE5X:` followed by one letter. 

So you need to write some code to take the data you 
want to send it, add the `STX` (`0x02`), calculate the 
`LEN` and add it, Calculate the `CRC`, add that, then finally 
add the `ETX` (`0x03`).

The `CRC` is always the hardest to get to work.  
`CRC` is `XOR` function between `LEN` byte and `DATA` bytes.  
http://en.wikipedia.org/wiki/Bitwise_operation#XOR 
You'll probably have to make a best guess as how to `XOR` the `DATA` and `LEN`,
then try it on the messages that the MicroAeth sends, and see if you get the
`CRC` that it produced.  

The `LEN` in the messages  from it seemed like they where one longer than the
number of data bytes, so you'll have to experiment with that.

Also the `LEN` is only 1 byte, and the `DATA` can be any number, so I think you
are  suppose to `XOR` the `LEN` with the first `DATA` byte, then take that and
XOR with the second, and so on, sort of like Xmodem.  I'm not sure which is the
first `DATA` byte, though.

This may help: http://crcmod.sourceforge.net/crcmod.html

Also just google for `XOR CRC`, finds some good stuff like
[this](http://stackoverflow.com/questions/344961/how-do-you-compute-the-xor-remainder-used-in-crc)

You should also make sure that when you send /x02 that it sends 00000010 not

01011100 01111000 00110000 00110010.

  # from http://aethlabs.com/sites/all/content/microaeth/microAeth%20Model%20AE51%20Operating%20Manual.pdf
  - Data(index)
  - Data(index+1)
  - Data(index+2)
  - ‘Sen1
  - Data(index+3)
  - Data(index+4)
  - Data(index+5)
  - ‘Sen2
  - Data(index+6)
  - Data(index+7)
  - Data(index+8)
  - ‘Flow
  - Data(index+9)
  - Data(index+10)
  - ‘PCBTemp
  - Data(index+11)
  - ‘Date
  - Data(index+12)
  - Data(index+13)
  - Data(index+14)
  - ‘Time
  - Data(index+15)
  - Data(index+16)
  - Data(index+17)
  - ‘Status
  - Data(index+18)
  - ‘Battery
  - Data(index+19)
  - Data(index+20)
  - ‘Reserved forGPS etc...
  - Data(index+21)
  - Data(index+22)
  - Data(index+23)
  - Data(index+24)
  - Data(index+25)
  - Data(index+26)
  - Data(index+27)
  - Data(index+28)
  - Data(index+29)
  - Data(index+30) 
=end
