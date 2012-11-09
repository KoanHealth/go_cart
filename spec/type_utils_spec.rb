require 'rspec'
require 'date'
require_relative '../lib/go_cart.rb'

describe "Infer types" do

  def check_em(test_data)
    test_data.each do |text, type|
      begin
        inferred_type = GoCart::TypeUtils.infer_type_symbol(text)
        inferred_type.should == type
      rescue
        raise unless type == :exception
      end
    end
  end

  it "should infer dates" do
    check_em({
      '01/02/2001' => :date,
      '2001/01/02' => :date,
      '01/02/9999' => :date,
      '1/2/2001' => :date,
      '2001/1/2' => :date,
      '9999/1/2' => :date,
      '01022001' => :date,
      '20010102' => :date,
      '12345678' => :integer,
      '12/34/5678' => :string,
    })
  end

  it "should infer numbers" do
    check_em({
      '1234' => :integer,
    })
    check_em({
      '12.34' => :decimal,
      '123.4' => :decimal,
    })
    check_em({
      '3.14159265359' => :float,
    })
  end

  it "should infer booleans" do
    check_em({
      'yes' => :boolean,
      'true' => :boolean,
      '1' => :boolean,
      'no' => :boolean,
      'false' => :boolean,
      '0' => :boolean,
    })
  end

end

describe "Upgrade types" do

  def check_em(test_data)
    test_data.each do |types, can_upgrade|
      begin
        answer = GoCart::TypeUtils.can_upgrade_type(types[0], types[1])
        answer.should == can_upgrade
      rescue
        puts "#{types[0]} -> #{types[1]}"
        raise unless can_upgrade == :exception
      end
    end
  end

  it "should upgrade types" do
    check_em({
       [ :string, :boolean ] => false,
       [ :string, :integer ] => false,
       [ :string, :date ] => false,
       [ :string, :float ] => false,
       [ :string, :decimal ] => false,
       [ :string, :string ] => true,

       [ :boolean, :boolean ] => true,
       [ :boolean, :integer ] => true,
       [ :boolean, :date ] => true,
       [ :boolean, :float ] => true,
       [ :boolean, :decimal ] => true,
       [ :boolean, :string ] => true,

       [ :integer, :boolean ] => false,
       [ :integer, :integer ] => true,
       [ :integer, :date ] => false,
       [ :integer, :float ] => true,
       [ :integer, :decimal ] => true,
       [ :integer, :string ] => true,

       [ :date, :boolean ] => false,
       [ :date, :integer ] => true,
       [ :date, :date ] => true,
       [ :date, :float ] => true,
       [ :date, :decimal ] => true,
       [ :date, :string ] => true,

       [ :float, :boolean ] => false,
       [ :float, :integer ] => false,
       [ :float, :date ] => false,
       [ :float, :float ] => true,
       [ :float, :decimal ] => false,
       [ :float, :string ] => true,

       [ :decimal, :boolean ] => false,
       [ :decimal, :integer ] => false,
       [ :decimal, :date ] => false,
       [ :decimal, :float ] => true,
       [ :decimal, :decimal ] => true,
       [ :decimal, :string ] => true,

    })
  end

end