require 'spec_helper'

module GoCart
  module StubCodeLookup
    extend self
    attr_accessor :valid_codes, :call_count

    def lookup_codes(code_array)
      self.call_count += 1
      code_array.select { |c| valid_codes.any? { |v| v == c } }
    end

    def reset_call_count
      self.call_count = 0
    end
  end

  class FakeGroupLambdaValidator < Validator
    validate_group 10, ->(values) { StubCodeLookup.lookup_codes(values) }
  end

  class FakeGroupClassFunctionValidator < Validator
    validate_group 10, :validate_unique_codes

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

    describe 'with valid input (lambda)' do
      let(:recorder) { recorder_lambda }
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

    describe 'with valid input (class)' do
      let(:recorder) { recorder_class }
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

    describe 'with invalid input' do
      let(:recorder) { recorder_lambda }
      before do
        100.times do |i|
          100.times do |j|
            recorder.validate(i* 200 + j, {one: true, two: true, three: 'moe'})
            recorder.validate(i* 200 + j + 1, {one: true, two: true, three: "bob-#{j}"})
          end
        end
      end

      it 'should report correct number of rows' do
        recorder.rows_processed.should eq 20000
      end

      it 'should report presence of errors' do
        recorder.has_errors?.should be_true
      end

      it 'should report correct number of errors' do
        recorder.total_errors.should eq 10000
      end

      it 'should report correct number of calls to validator' do
        recorder.total_errors #force final evaluation of all errors
        StubCodeLookup.call_count.should be <= 11
      end
    end

    describe 'when testing validator, results should be immediately tested' do
      before do
        StubCodeLookup.reset_call_count
        StubCodeLookup.valid_codes = %w(larry moe curly)
      end

      let (:validator) {FakeGroupLambdaValidator.new}
      it 'with invalid input, should immediately report error' do
        validator.test('frank').has_errors?.should be_true
      end

      it 'every call to test_validate should invoke the remote service' do
        validator.test('frank')
        validator.test('larry')
        validator.test('moe')
        StubCodeLookup.call_count.should be == 3
      end

      it 'repeated calls (with same value) to test_validate should always invoke the remote service' do
        validator.test('moe')
        validator.test('moe')
        validator.test('moe')
        StubCodeLookup.call_count.should be == 3
      end

    end


  end
end