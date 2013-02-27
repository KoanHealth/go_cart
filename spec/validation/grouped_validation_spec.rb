require 'spec_helper'

module GoCart
  module StubCodeLookup
    extend self
    attr_accessor :valid_codes, :call_count

    def lookup_codes(code_array)
      self.call_count += 1
      code_array.select { |c| valid_codes.find(c) }
    end

    def reset_call_count
      self.call_count = 0
    end
  end

  class FakeGroupLambdaValidator < Validator
    #validate_group 500, :validate_unique_codes
    validate_group 500, ->(values) {StubCodeLookup.lookup_codes(values)}

    def self.validate_unique_codes(values)
      StubCodeLookup.lookup_codes(values)
    end
  end

  class FakeGroupClassFunctionValidator < Validator
    #validate_group 500, :validate_unique_codes
    validate_group 500, ->(values) {StubCodeLookup.lookup_codes(values)}

    def self.validate_unique_codes(values)
      StubCodeLookup.lookup_codes(values)
    end
  end

  describe 'Grouped Validation Spec' do
    class GroupedSimpleFormat < GoCart::Format
      def initialize
        super
        create_table :simple_format_lambda, :headers => true, :name => 'simple_format_lambda' do |t|
          t.boolean :one, header: :one
          t.boolean :two, header: :two
          t.string :three, header: :three, :validation => :fake_group_lambda
        end
        create_table :simple_format_class, :headers => true, :name => 'simple_format_class' do |t|
          t.boolean :one, header: :one
          t.boolean :two, header: :two
          t.string :three, header: :three, :validation => :fake_group_class_function
        end
      end
    end

    before do
      StubCodeLookup.reset_call_count
      StubCodeLookup.valid_codes = %w(larry moe curly)
    end


    let(:recorder_lambda) { ValidationRecorder.new(GroupedSimpleFormat.new.get_table(:simple_format_lambda)) }
    let(:recorder_class) { ValidationRecorder.new(GroupedSimpleFormat.new.get_table(:simple_format_class)) }

    describe "with valid input (lambda)" do
      let(:recorder) {recorder_lambda}
      before do
        100.times do |v|
          recorder.validate(v, {one: true, two: true, three: 'moe'})
        end
      end

      it 'should report correct number of rows' do
        recorder.rows_processed.should eq 100
      end

      it 'should report no errors' do
        recorder.has_errors?.should be_false
      end

      it 'should report correct number of calls to validator' do
        recorder.total_errors #force final evaluation of all errors
        StubCodeLookup.call_count.should eq 1

      end
    end

    describe "with valid input (class)" do
      let(:recorder) {recorder_class}
      before do
        100.times do |v|
          recorder.validate(v, {one: true, two: true, three: 'moe'})
        end
      end

      it 'should report correct number of rows' do
        recorder.rows_processed.should eq 100
      end

      it 'should report no errors' do
        recorder.has_errors?.should be_false
      end

      it 'should report correct number of calls to validator' do
        recorder.total_errors #force final evaluation of all errors
        StubCodeLookup.call_count.should eq 1

      end
    end

  end
end