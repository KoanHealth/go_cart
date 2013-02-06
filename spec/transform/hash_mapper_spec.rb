require "spec_helper"

module GoCart

  describe "Hash Mapper" do
    class SimpleFormat < GoCart::Format
      def initialize
        super
        create_table :simple_format, :headers => true, :name => "simple_format" do |t|
          t.boolean(:field_one, header: :field_one)
          t.boolean(:field_two, header: :field_two)
          t.string(:field_three, header: :field_three)
          t.integer(:field_four, header: :field_four)
        end
      end
    end

    let(:simple_row_headers) { %w(field_one field_two field_three field_four).map(&:to_sym) }
    let(:simple_row_data0) { [false, false, "bob", "0"].map(&:to_s) }
    let(:simple_row_data1) { [false, true, "fred", "1"].map(&:to_s) }
    let(:simple_row_data2) { [true, false, "mary", "2"].map(&:to_s) }
    let(:simple_row_data3) { [true, true, "jane", "3"].map(&:to_s) }
    let(:simple_row) { CSV::Row.new(simple_row_headers, simple_row_data0) }
    let(:simple_row0) { simple_row }
    let(:simple_row1) { CSV::Row.new(simple_row_headers, simple_row_data1) }
    let(:simple_row2) { CSV::Row.new(simple_row_headers, simple_row_data2) }
    let(:simple_row3) { CSV::Row.new(simple_row_headers, simple_row_data3) }


    def check_simple_result(result)
      result[:field_one].should eq "false"
      result[:field_two].should eq "false"
      result[:field_three].should eq "bob"
      result[:field_four].should eq "0"
    end

    describe "basic 1:1 mapping without configuration" do
      let(:mapper) { HashMapper.new }
      it "should map values as strings" do
        result = mapper.map(simple_row)
        result.should be_kind_of Hash

        check_simple_result(result)
      end
    end

    describe "basic 1:1 mapping with configuration from row" do
      let(:mapper) { HashMapper.new(simple_row) }
      it "should map values as strings" do
        result = mapper.map(simple_row)
        result.should be_kind_of Hash
        check_simple_result(result)
      end

      it "should reject rows with smaller number of elements" do
        row = CSV::Row.new(simple_row_headers.dup.pop(3), simple_row_data0.dup.pop(3))
        -> { mapper.map(row) }.should raise_exception
      end

      it "should reject rows with larger number of elements" do
        row = CSV::Row.new(simple_row_headers.dup.push(:extra), simple_row_data0.dup.push('read all about it'))
        -> { mapper.map(row) }.should raise_exception
      end
    end

    describe "Mapper configuration with GoCart table spec" do
      let(:table) { SimpleFormat.new().get_table(:simple_format) }
      let(:mapper) { HashMapper.new(table) }

      it "should map values as correct types" do
        result = mapper.map(simple_row0)
        result[:field_one].should be_false
        result[:field_two].should be_false
        result[:field_three].should eq "bob"
        result[:field_four].should eq 0

        result = mapper.map(simple_row1)
        result[:field_one].should be_false
        result[:field_two].should be_true
        result[:field_three].should eq "fred"
        result[:field_four].should eq 1
      end

      it "should reject rows with smaller number of elements" do
        row = CSV::Row.new(simple_row_headers.dup.pop(3), simple_row_data0.dup.pop(3))
        -> { mapper.map(row) }.should raise_exception
      end

      it "should reject rows with larger number of elements" do
        row = CSV::Row.new(simple_row_headers.dup.push(:extra), simple_row_data0.dup.push('read all about it'))
        -> { mapper.map(row) }.should raise_exception
      end

      it "when empty block is supplied for configuration, all rows should map to empty hash" do
        new_mapper = HashMapper.new(table) {}
        new_mapper.map(simple_row0).should be_empty
        new_mapper.map(simple_row1).should be_empty
      end

      it "direct map all fields" do
        new_mapper = HashMapper.new(table) do |m|
          m.simple_map_others
        end

        result = new_mapper.map(simple_row0)
        result[:field_one].should be_false
        result[:field_two].should be_false
        result[:field_three].should eq "bob"
        result[:field_four].should eq 0

        result = mapper.map(simple_row1)
        result[:field_one].should be_false
        result[:field_two].should be_true
        result[:field_three].should eq "fred"
        result[:field_four].should eq 1
      end

      it "direct map subset of fields" do
        new_mapper = HashMapper.new(table) do |m  |
          m.simple_map(:field_one, :field_four)
        end

        result = new_mapper.map(simple_row0)
        result[:field_one].should be_false
        result[:field_two].should be_nil
        result[:field_three].should be_nil
        result[:field_four].should eq 0
      end

      it "perform operation on field" do
        new_mapper = HashMapper.new(table) do |m|
          m.map(:field_three) { |v| v.upcase.reverse }
        end

        result = new_mapper.map(simple_row1)
        result[:field_one].should be_nil
        result[:field_two].should be_nil
        result[:field_three].should eq "DERF"
        result[:field_four].should be_nil
      end

      it "perform operation and rename on field" do
        new_mapper = HashMapper.new(table) do |m|
          m.map(:reversed_name, :field_three) { |v| v.upcase.reverse }
        end

        result = new_mapper.map(simple_row1)
        result.count.should eq 1
        result[:reversed_name].should eq "DERF"
      end

      it "perform operation on field with simple_map_others" do
        new_mapper = HashMapper.new(table) do |m|
          m.map(:field_three) { |v| v.upcase.reverse }
          m.simple_map_others
        end

        result = new_mapper.map(simple_row1)
        result[:field_one].should be_false
        result[:field_two].should be_true
        result[:field_three].should eq "DERF"
        result[:field_four].should eq 1
      end

      it "splitting an input to an array should be possible in a block" do

        new_mapper = HashMapper.new(table) do |m|
          m.map(:field_three) { |v| v.split(" ") }
          m.simple_map_others
        end

        row = CSV::Row.new(simple_row_headers, [true, true, "dick jane fred wilma", "3"].map(&:to_s))

        result = new_mapper.map(row)

        result[:field_three].count.should eq 4
        result[:field_three].should include('dick')
        result[:field_three].should include('jane')
        result[:field_three].should include('fred')
        result[:field_three].should include('wilma')

      end
    end
  end
end
