require 'spec_helper'
require 'date'

describe "Extract Values" do

  def check_em(type, test_data)
    test_data.each do |text, value|
      begin
        extracted_value = GoCart::DataUtils.extract_value(type, text)
        extracted_value.should == value
      rescue
        raise unless value == :exception
      end
    end
  end

  it "should extract dates" do
    check_em(:date, {
      '01/02/2001' => Date.new(2001,1,2),
      '2001/01/02' => Date.new(2001,1,2),
      '99/99/9999' => nil,
      '0000/00/00' => nil,
      '1/2/2001' => Date.new(2001,1,2),
      '2001/1/2' => Date.new(2001,1,2),
      '99999999' => nil,
      '00000000' => nil,
      '01022001' => Date.new(2001,1,2),
      '20010102' => Date.new(2001,1,2),
      '10011934' => Date.new(1934,10,1),
      '19341011' => Date.new(1934,10,11),
      '3/23/2012 4:48:29' => Date.new(2012,3,23),
      '12345678' => :exception,
      '12/34/5678' => :exception,
    })
  end

  it "should extract numbers" do
    check_em(:integer, {
      '1234' => 1234,
      '-1234' => -1234,
      '12.34' => :exception,
    })
    check_em(:decimal, {
      '12.34' => 12.34,
      '1E4' => 1e4,
      '1X4' => :exception,
    })
    check_em(:float, {
      '3.14159265359' => 3.14159265359,
      'testing' => :exception,
    })
  end

  it "should extract booleans" do
    check_em(:boolean, {
      'yes' => true,
      'true' => true,
      '1' => true,
      'no' => false,
      'false' => false,
      '0' => false,
      '100' => :exception,
      'on' => :exception,
    })
  end

  it "should extract and trim strings" do
    check_em(:string, {
      'GoCart' => 'GoCart',
      " GoCart\t   \r\n" => 'GoCart',
    })
  end

end