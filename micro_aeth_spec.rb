require './micro_aeth.rb'
require 'pry'

include MicroAeth

describe MicroAeth do
  describe ::String do
    it "returns the arrording integer represented by the byte passed" do
      "\x00".byte.should equal 0
    end
    it "XORs two strings" do
      (0.chr ^ 1.chr ).should eq 1.chr
    end
  end
  describe Message do 
    it "initializes a Message with valid data string" do
      message_string = "%AE5X:M\x06\x12\x00\xEE\x00~\x17\x00\x00\x00&\r\x06\x12\x19\x14@d\x00\x03\x04\x05\x06\a\b\t\n\v\f\xB1"
      Message.new message_string
    end
    it "initializes a Message with valid data string" do
      message_string = "%AE5X:M\xF5\x00\x91\x00e\x17\x00\x00\x00 \r\x06\x12\b\x1F\x03@d\x00\x03\x04\x05\x06\a\b\t\n\v\f+"
      Message.new message_string
    end
    it "validates a string of data" do
      m = Message.new "%AE5X:M\xF5\x00\x91\x00e\x17\x00\x00\x00 \r\x06\x12\b\x1F\x03@d\x00\x03\x04\x05\x06\a\b\t\n\v\f+"
      m.instance_eval{ data_valid? "abcd"}.should equal false
    end
  end
  describe Com do
    it "initialized a Com" do
      com = Com.new
    end
    it "turns the MicroAeth off" do
      t = Time.now
      len = 21.chr 
      m = "AE5X:O" + 
          1.chr +  # Power OFF enabled
          (t.year - 2000).chr +
          t.month.chr +
          t.day.chr +
          t.hour.chr +
          t.min.chr +
          t.sec.chr +
          0.chr + # Power ON enabled
          (t.year - 2000).chr +
          t.month.chr +
          t.day.chr +
          t.hour.chr +
          t.min.chr +
          t.sec.chr
      binding.pry
      crc = m ^ len
      com = Com.new
      com.write_message "\x02" + len + m + crc + "\x03"
    end
  end
end

=begin
# some messages
"%AE5X:M\x06\x12\x00\xE6\x11\x00e\x17\x00\x00\x00\"\r\x00\x06\r\f\x18\x13@d\x00"
"%AE5X:M\xD0\x11\x00\xC2\x11\x00[\x17\x00\x00\x00\"\r\x06\r\f\x18\x14@d\x00"
"\x00%AE5X:M\xF3\x11\x00\xD9\x11\x00a\x17\x00\x00\x00\"\r\x06\r\f\x18\x15@d\x00"
%AE5X:M\x06\x12\x00\xEE\x00~\x17\x00\x00\x00&\r\x06\x12\x19\x14@d\x00\x03\x04\x05\x06\a\b\t\n\v\f\xB1
%AE5X:M\x02\x12\x00\x8D\x00b\x17\x00\x00\x00 \r\x06\x12\b\x1E8@d\x00\x03\x04\x05\x06\a\b\t\nv\f\xFE
=end
