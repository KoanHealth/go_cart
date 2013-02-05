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
    let(:simple_row0) {simple_row}
    let(:simple_row1) { CSV::Row.new(simple_row_headers, simple_row_data1) }
    let(:simple_row2) { CSV::Row.new(simple_row_headers, simple_row_data2) }
    let(:simple_row3) { CSV::Row.new(simple_row_headers, simple_row_data3) }

    let(:simple_map) { {field_one: :field_one, field_two: :field_two, field_three: :field_three, field_four: :field_four} }
    let(:simple_map_changes_names) { {uno: :field_one, dos: :field_two, tres: :field_three, quatro: :field_four} }


    def check_simple_result(result)
      result[:field_one].should eq "false"
      result[:field_two].should eq "false"
      result[:field_three].should eq "bob"
      result[:field_four].should eq "0"
    end
    describe "basic 1:1 mapping without configuration" do
      let(:mapper) {HashMapper.new}
      it "should map values as strings" do
        result = mapper.map(simple_row)
        result.should be_kind_of Hash

        check_simple_result(result)
      end
    end

    describe "basic 1:1 mapping with configuration from row" do
      let(:mapper) {HashMapper.new(simple_row)}
      it "should map values as strings" do
        result = mapper.map(simple_row)
        result.should be_kind_of Hash
        check_simple_result(result)
      end

      it "should reject rows with smaller number of elements" do
        row = CSV::Row.new(simple_row_headers.dup.pop(3), simple_row_data0.dup.pop(3))
        ->{mapper.map(row)}.should raise_exception
      end

      it "should reject rows with larger number of elements" do
        row = CSV::Row.new(simple_row_headers.dup.push(:extra), simple_row_data0.dup.push('read all about it'))
        ->{mapper.map(row)}.should raise_exception
      end
    end

    describe "1:1 mapping described with hash" do
      let(:mapper) {HashMapper.new(simple_map)}

      it "should map values as strings" do
        result = mapper.map(simple_row)
        result.should be_kind_of Hash
        check_simple_result(result)
      end

      it "should reject rows with smaller number of elements" do
        row = CSV::Row.new(simple_row_headers.dup.pop(3), simple_row_data0.dup.pop(3))
        ->{mapper.map(row)}.should raise_exception
      end

      it "should reject rows with larger number of elements" do
        row = CSV::Row.new(simple_row_headers.dup.push(:extra), simple_row_data0.dup.push('read all about it'))
        ->{mapper.map(row)}.should raise_exception
      end
    end

    describe "1:1 mapping configured with row and hash" do
      let(:mapper) {HashMapper.new(simple_row, simple_map)}

      it "should map values as strings" do
        result = mapper.map(simple_row)
        result.should be_kind_of Hash
        check_simple_result(result)
      end

      it "should reject rows with smaller number of elements" do
        row = CSV::Row.new(simple_row_headers.dup.pop(3), simple_row_data0.dup.pop(3))
        ->{mapper.map(row)}.should raise_exception
      end

      it "should reject rows with larger number of elements" do
        row = CSV::Row.new(simple_row_headers.dup.push(:extra), simple_row_data0.dup.push('read all about it'))
        ->{mapper.map(row)}.should raise_exception
      end
    end

    describe "Mapper configuration with GoCart table spec" do
      let(:table) {SimpleFormat.new().get_table(:simple_format)}
      let(:mapper) {HashMapper.new(table)}

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
        ->{mapper.map(row)}.should raise_exception
      end

      it "should reject rows with larger number of elements" do
        row = CSV::Row.new(simple_row_headers.dup.push(:extra), simple_row_data0.dup.push('read all about it'))
        ->{mapper.map(row)}.should raise_exception
      end

      it "when empty block is supplied for configuration, all rows should map to empty hash" do
        new_mapper = HashMapper.new(table) {}
        new_mapper.map(simple_row0).should be_empty
        new_mapper.map(simple_row1).should be_empty
      end

    end

    describe "mapping configured for name changes" do
      let(:mapper) {HashMapper.new(simple_map_changes_names)}

      it "specified as hash should map values as strings" do
        result = mapper.map(simple_row0)
        result[:uno].should eq "false"
        result[:dos].should eq "false"
        result[:tres].should eq "bob"
        result[:quatro].should eq "0"

        result = mapper.map(simple_row1)
        result[:uno].should eq "false"
        result[:dos].should eq "true"
        result[:tres].should eq "fred"
        result[:quatro].should eq "1"

        result = mapper.map(simple_row2)
        result[:uno].should eq "true"
        result[:dos].should eq "false"
        result[:tres].should eq "mary"
        result[:quatro].should eq "2"

        result = mapper.map(simple_row3)
        result[:uno].should eq "true"
        result[:dos].should eq "true"
        result[:tres].should eq "jane"
        result[:quatro].should eq "3"
      end
    end


  end
end
