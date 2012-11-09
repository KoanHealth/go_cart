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
      '01/02/9999' => Date.new(9999,1,2),
      '1/2/2001' => Date.new(2001,1,2),
      '2001/1/2' => Date.new(2001,1,2),
      '9999/1/2' => Date.new(9999,1,2),
      '01022001' => Date.new(2001,1,2),
      '20010102' => Date.new(2001,1,2),
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