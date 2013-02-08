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

      describe "Conditional Operations" do
        it "should conditionally map rows" do
          mapper = HashMapper.new(table) do |m|
            m.if(->(row) { row[:field_one] }) do |i|
              i.map(:name, :field_three) { |v| v.upcase }
            end
          end

          mapper.map(simple_row0).should be_nil
          mapper.map(simple_row1).should be_nil
          mapper.map(simple_row2)[:name].should eq 'MARY'
          mapper.map(simple_row3)[:name].should eq 'JANE'
        end

        it "should conditionally map rows with unless" do
          mapper = HashMapper.new(table) do |m|
            m.unless(->(row) { row[:field_one] }) do |u|
              u.map(:name, :field_three) { |v| v.upcase }
            end
          end

          mapper.map(simple_row0)[:name].should eq 'BOB'
          mapper.map(simple_row1)[:name].should eq 'FRED'
          mapper.map(simple_row2).should be_nil
          mapper.map(simple_row3).should be_nil
        end

        it "should handle chained conditionals" do
          # If you actually do this, you're probably acting like an idiot, but I thought I should make sure it works
          mapper = HashMapper.new(table) do |m|
            m.if(->(row) { row[:field_one] }).if(->(row) { row[:field_two] }) do |i|
              i.map(:name, :field_three) { |v| v.upcase }
            end
          end
          # If you actually do this, you're probably acting like an idiot

          mapper.map(simple_row0).should be_nil
          mapper.map(simple_row1).should be_nil
          mapper.map(simple_row2).should be_nil
          mapper.map(simple_row3)[:name].should eq 'JANE'
        end

        it "look - you can put multiple expressions in the condition lambda" do
          # If you actually do this, you're probably acting like an idiot, but I thought I should make sure it works
          mapper = HashMapper.new(table) do |m|
            m.if(->(row) { row[:field_one] && row[:field_two] }) do |i|
              i.map(:name, :field_three) { |v| v.upcase }
            end
          end
          # If you actually do this, you're probably acting like an idiot

          mapper.map(simple_row0).should be_nil
          mapper.map(simple_row1).should be_nil
          mapper.map(simple_row2).should be_nil
          mapper.map(simple_row3)[:name].should eq 'JANE'
        end
      end

      describe "Mapping Rows" do
        it "should allow a field to be mapped from a row" do
          mapper = HashMapper.new(table) do |m|
            m.map(:title, ->(row) { "#{row[:field_three].capitalize} the #{row[:field_two] ? 'Useful' : 'Useless'}" })
          end

          mapper.map(simple_row0)[:title].should eq 'Bob the Useless'
          mapper.map(simple_row1)[:title].should eq 'Fred the Useful'
          mapper.map(simple_row2)[:title].should eq 'Mary the Useless'
          mapper.map(simple_row3)[:title].should eq 'Jane the Useful'

        end

        it "Row mapping can also be used to produce sub objects" do
          new_mapper = HashMapper.new(table) do |m|
            m.map :sub1, ->(r) do
              {
                  name: r[:field_three].upcase,
                  useful: r[:field_one]
              }
            end
            m.map :sub2, ->(r) do
              {
                  present: r[:field_two],
                  count: r[:field_four]
              }
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

        it "splitting a row to a sub hash should be possible in a block" do

          new_mapper = HashMapper.new(table) do |m|
            m.map_object(:sub1) do |row|
              {name: row[:field_three].upcase, useful: row[:field_one]}
            end
            m.map_object(:sub2) do |row|
              {present: row[:field_two], count: row[:field_four]}
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

      end


      describe "Complex Operations" do

      end
    end


    describe "Complex Operations" do

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
            m.array(:conditions, include_empty: true) do |a|
              FauxFormats.conditions.each do |c|
                a.map_object do |row|
                  source = row["#{c}_condition"]
                  unless source.to_s.blank?
                    {
                        name: c,
                        source: source,
                        rx_gaps: row["#{c}_rx_gaps"],
                        mpr: row["#{c}_mpr"],
                        csa: row["#{c}_csa"],
                        rx_untreated: row["#{c}_rx_untreated"]
                    }
                  end
                end
              end
            end


            #m.array(:conditions, include_empty: true) do |a|
            #
            #  FauxFormats.conditions.each do |c|
            #    condition = "#{c}_condition".to_sym
            #    a.map_object.unless(->(row) { row[condition].to_s.blank? }) do |obj|
            #      obj.map(:source, condition)
            #      obj.map(:rx_gaps, "#{c}_rx_gaps".to_sym)
            #      obj.map(:mpr, "#{c}_mpr".to_sym)
            #      obj.map(:csa, "#{c}_csa".to_sym)
            #      obj.map(:rx_untreated, "#{c}_rx_untreated".to_sym)
            #      obj.constant(:name, c)
            #    end
            #  end
            #
            #end


          end
        end

        it "should produce a two element hash, with :conditions being an array " do
          result = mapper.map(CSV::Row.new(assessment_row_headers, assessment_row_data0))
          result[:member_id].should eq "A001"
          result[:conditions].should be_kind_of Array
          result[:conditions].length.should eq 2
          result[:conditions][0][:name].should eq "congestive_heart_failure"
          result[:conditions][1][:name].should eq "diabetes"
        end
      end
    end
  end
end

#TODO - Be able to skip mapping elements if the results are not meaningful


#TODO - Re-mapping a field that is not an array should raise an exception
#TODO - Fix Array operations, block and declaration