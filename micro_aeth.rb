require 'serialport'
require 'timeout'

module MicroAeth
  class ::String
    ###
    # @return the first charater in the string as an integer
    def byte
      self.bytes[0]
    end

    ### 
    # XOR two strings
    # @str assumed to be a one byte string or integer
    def ^ str
      if str.class == String
        str = str.byte
      elsif str.class == Fixnum
        nil
      else
        raise "invalid arg: #{str.class} \n Must be String or Fixnum"
      end
      self.bytes.each do |i|
        str = str ^ i
      end
      str.chr.force_encoding( "ASCII-8BIT")
    end
  end

  class Instruction
    ###
    # Message constants
    STX = "\x02" # Start of each message
    ETX = "\x03" # End of each message
    M = "AE5X:" # What each message starts with
    EraseFlash = "E" # Reply:ACK, after flash is erased anotherACK issent.(erasing should take 30 – 45 seconds)
    StopWrite = "S" # stopswriting to flash
    StartWrite = "W" # Startswriting to flash
    Kill = "K" # Kill Shuts down microAeth
  end

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

    ###
    # @param data [String] conents between the `STX` "\x02"
    #   and the `ETX` "0x03"
    def initialize data
      raise "invalid data" unless data_valid? data
      @original_char_string = data
      parse_data( data[7..-1])
    end

    private
      def data_valid? d
        crc = d[-1]
        data = d[1..-2]
        len = d[0]
        (data ^ len).byte == crc.byte
      end
      def parse_data d
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
      port     = '/dev/serial/by-id/usb-AethLabs_microAeth_Model_AE51_AE51-S4-649-1303-if00-port0'
      baud     = 500_000
      bytesize = 8
      stopbits = 1
      parity   = SerialPort::MARK
      @com     = SerialPort.new port, baud, bytesize, stopbits, parity
      @messages = []
    end

    ###
    # @m The message to be written
    def write instruction
      data = MicroAeth::Instruction::M + instruction
      len = data.length.chr
      crc = data ^ len
      @com.write (MicroAeth::Instruction::STX + len + data + crc + MicroAeth::Instruction::ETX).force_encoding("ASCII-8BIT")
    end

    def erase_flash
      begin 
        clear_buffer
        write MicroAeth::Instruction::EraseFlash
        Timeout::timeout(60) { wait_for_acknowledge }
        sleep 45
        Timeout::timeout(60) { wait_for_acknowledge }
        write MicroAeth::Instruction::StartWrite
        Timeout::timeout(60) { wait_for_acknowledge }
      rescue Timeout::Error
        retry
      end 
    end
    def clear_buffer
      begin
        while true 
          Timeout::timeout(0.5) { read_message }
        end
      rescue Timeout::Error
        nil
      end
    end

    def wait_for_acknowledge
      while read_message != "\u0006AE5X:A\u0014".force_encoding("ASCII-8BIT")
        nil
      end
    end

    def start
      begin 
        erase_flash
      rescue EOFError
        raise "Problem stating the MicroAeth"
      end
    end

    ##
    # @return A ruby thread which continually reads
    #   from the MicroAeth::Com#com instance
    def read
      @com_thread = Thread.new do
        begin
          while true
            @messages << ( Message.new read_message )
          end
        # Intermitently, it the serialport library raises end of file...
        rescue EOFError
          sleep 1
          retry
        end 
      end
    end
    
    ###
    # @file a ruby file object
    def start_write_to_file file_name
      @stop_writing_to_file = false
      @thread = Thread.new do
        clear_buffer
        m_prev = nil
        while @stop_writing_to_file != true
          begin
            m = Message.new read_message
          rescue RuntimeError
            retry
          end
          erase_flash if m.status == 64
          atn = Math.log( m.ref.to_f / m.sen1.to_f) * 100
          file = File.new file_name, 'a'
          message = [Time.now, m.ref, m.sen1, atn, m.flow, m.pcb_temp, m.status, m.battery, sigma_ap( m, m_prev)].join(',') + "\n"
          file << message
          file.close
          m_prev = m
        end
      end
    end
    def stop_write_to_file
      @stop_writing_to_file = true
      @thread.join 30
    end

    def sigma_ap m, m_prev
      if m_prev.nil? 
        "NaN" 
      else 
        Math::PI * (0.3 ** 2) / 4.0 / m.flow.to_f * 60.0 * 
          Math.log( m_prev.sen1.to_f / m.sen1.to_f * m.ref.to_f / m_prev.ref.to_f) * (10.0 ** 8)
      end
    end
    def read_message
      m, c = '',''
      while c != "\x02"; c = @com.readchar; end
      c = @com.readchar
      m << c
      len = c.byte
      0.upto len do |i|
        c = @com.readchar
        m << c
      end
      while c != "\x03"
        c = @com.readchar
        m << c
      end
      m[0..-2]
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

Acknowledge: "\u0006AE5X:A\u0014" 
=end
