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
  end
  describe Com do
    it "calculates a sigma_ap properly" do
      class TestMessage; attr_accessor :sen1, :flow, :ref; end
      m = TestMessage.new; m.ref = 870015.0; m.sen1 = 882687.0; m.flow = 49.0
      m_prev = TestMessage.new; m_prev.ref = 870007.0; m_prev.sen1 = 882680.0; m_prev.flow = 48.0
      sigma_ap( m, m_prev).should be_close( 10.948_430_970_2, 0.000_000_000_1)
    end
    it "calculates a sigma_ap properly" do
      class TestMessage; attr_accessor :sen1, :flow, :ref; end
      m = TestMessage.new; m.ref = 870015.0; m.sen1 = 882687.0; m.flow = 49.0
      m_prev = nil
      sigma_ap( m, m_prev).should eq( "NaN")
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
