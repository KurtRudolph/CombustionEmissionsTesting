require 'serialport'

class Message
  attr :original_char_string,
       :ref,
       :sen1,
       :sen2,
       :flow,
       :pcb_temp,
       :date,
       :time,
       :status,
       :battery
##
# data - bytes of data passed as a char string
  def initialize data
    @original_char_string = data
    b = data.bytes

    @ref = b[0..2]
    @sen1 = b[3..5]
    @sen2 = b[6..8]
    @flow = b[9..10]
    @pcb_temp = b[11]
    @time = Time.new ('20' + b[12].to_s).to_i, b[13], b[14], b[15], b[16], b[17]
    @status = b[18]
    @battery = b[19..20]
  end
end
  

=begin
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

class MicroAeth
  attr_accessor :com

  def initialize
    port     = '/dev/ttyUSB1'
    baud     = 500_000
    bytesize = 8
    stopbits = 1
    parity   = SerialPort::MARK
    @com     = SerialPort.new port, baud, bytesize, stopbits, parity
  end

  def read_message
    message = ''
    while @com.readchar != "\x02"
      nil
    end
    while (c = @com.readchar) != "\x03"
      message = message + c
    end
    Message.new message[7..-1]
  end
end
