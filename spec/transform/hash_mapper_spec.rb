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
        new_mapper.map(simple_row0).should be_nil
        new_mapper.map(simple_row1, return_empty_objects: true).should be_empty
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
        new_mapper = HashMapper.new(table) do |m|
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

      it "produce a constant" do
        new_mapper = HashMapper.new(table) do |m|
          m.constant(:ex_machina) { "ghost" }
          m.constant(:ex_politca, "errors")
        end

        result = new_mapper.map(simple_row1)
        result[:field_one].should be_nil
        result[:field_two].should be_nil
        result[:field_three].should be_nil
        result[:field_four].should be_nil
        result[:ex_machina].should eq "ghost"
        result[:ex_politca].should eq "errors"
      end

      it "constant cannot be configured with both a value and a block" do
        -> { HashMapper.new(simple_row1, table) { |m| m.constant(:ex_machina, "this is ") { "an error" } }
        }.should raise_exception
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
        end

        row = CSV::Row.new(simple_row_headers, [true, true, "dick jane fred wilma", "3"].map(&:to_s))

        result = new_mapper.map(row)

        result[:field_three].count.should eq 4
        result[:field_three].should include('dick')
        result[:field_three].should include('jane')
        result[:field_three].should include('fred')
        result[:field_three].should include('wilma')

      end

      it "splitting a row to a sub hash should be possible in a block" do

        new_mapper = HashMapper.new(table) do |m|
          m.map_object(:sub1) do |r|
            r.map(:name, :field_three) { |v| v.upcase }
            r.map(:useful, :field_one)
          end
          m.map_object(:sub2) do |r|
            r.map(:present, :field_two)
            r.map(:count, :field_four)
          end
        end

        row = CSV::Row.new(simple_row_headers, [true, true, "dick", 3].map(&:to_s))

        result = new_mapper.map(row)
        result.count.should eq 2
        result[:sub1].count.should eq 2
        result[:sub2].count.should eq 2

        result[:sub1][:name].should eq "DICK"
        result[:sub1][:useful].should be_true

        result[:sub2][:count].should eq 3
        result[:sub2][:present].should be_true
      end

      describe "Conditional Operations" do
        let(:mapper) do
          HashMapper.new(table) do |m|
            m.if(->(row) { row[:field_one] }) do |i|
              i.map(:name, :field_three) {}
            end
          end
        end

        it "should conditionally map rows" do
          mapper.map(simple_row0).should be_nil
          mapper.map(simple_row1).should be_nil
          mapper.map(simple_row2)[:name].should eq 'MARY'
          mapper.map(simple_row3)[:name].should eq 'JANE'
        end
      end


    end


    describe "ArrayOperations" do

      class FauxFormats < GoCart::Format
        def self.conditions
          %w{congestive_heart_failure depression diabetes}
        end

        def self.indications
          %w{condition rx_gaps mpr csa rx_untreated}
        end

        def self.assessment_row_headers
          result = [:member_id]
          conditions.each { |c| indications.each { |i| result.push "#{c}_#{i}".to_sym } }
          result
        end

        def initialize
          super
          create_table :faux_assessment, :headers => true, :name => "faux_assessment" do |t|
            FauxFormats.assessment_row_headers.each { |h| t.string h, header: h }
          end
        end
      end


      let(:assessment_row_headers) { FauxFormats.assessment_row_headers }
      let(:assessment_table) { FauxFormats.new().get_table(:faux_assessment) }
      let(:assessment_row_data0) { ["A001", "Rx", "", "", "", "N", "", "", "", "", "", "ICD", "2", "", "", "P"] }

      it "validate data" do
        mapper = HashMapper.new(assessment_table)
        result = mapper.map(CSV::Row.new(assessment_row_headers, assessment_row_data0))

        result[:member_id].should eq "A001"
        result[:congestive_heart_failure_condition].should eq "Rx"
        result[:diabetes_rx_untreated].should eq "P"
      end

      describe "Basic pivot operations" do
        let(:mapper) do
          HashMapper.new(assessment_table) do |m|
            m.map :member_id

            FauxFormats.conditions.each do |c|
              condition = "#{c}_condition".to_sym
              m.map_object(:conditions, {array: true}) do |r|
                r.map(:source, condition)
                r.map(:rx_gaps, :"#{c}_rx_gaps".to_sym)
                r.map(:mpr, :"#{c}_mpr".to_sym)
                r.map(:csa, :"#{c}_csa".to_sym)
                r.map(:rx_untreated, :"#{c}_rx_untreated".to_sym)
                r.constant(:name, c)
              end
            end

            m.array(:conditions, include_empty: true) do |a|

              FauxFormats.conditions.each do |c|
                condition = "#{c}_condition".to_sym
                a.map_object.unless(->(row) { row[condition].to_s.blank? }) do |obj|
                  obj.map(:source, condition)
                  obj.map(:rx_gaps, "#{c}_rx_gaps".to_sym)
                  obj.map(:mpr, "#{c}_mpr".to_sym)
                  obj.map(:csa, "#{c}_csa".to_sym)
                  obj.map(:rx_untreated, "#{c}_rx_untreated".to_sym)
                  obj.constant(:name, c)
                end
              end

            end


          end
        end

        it "should produce a two element hash, with :conditions being an array " do
          result = mapper.map(CSV::Row.new(assessment_row_headers, assessment_row_data0))
          result[:member_id].should eq "A001"
          result[:conditions].should be_kind_of Array
          result[:conditions][0][:name].should eq "congestive_heart_failure"
          result[:conditions][1][:name].should eq "depression"
          result[:conditions][2][:name].should eq "diabetes"
        end
      end


    end
  end
end

#TODO - Be able to skip mapping elements if the results are not meaningful


#TODO - Re-mapping a field that is not an array should raise an exception
#TODO - Dump nil fields, but have option to force their inclusion
