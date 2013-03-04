require 'spec_helper'

module GoCart

  describe ValidationRecorder do
    class ValidationRecorderFormat < GoCart::Format
      def initialize
        super
        create_table :simple_format, :headers => true, :name => 'simple_format' do |t|
          t.boolean :one, header: :one
          t.boolean :two, header: :two
          t.string :three, header: :three, :validation => :required_field
          t.integer :four, header: :four
          t.string :five, header: :five, :validation => RegexValidator.new(/^rose(bud)?$/, 'Verify Roses')
        end
      end
    end

    let(:recorder) { recorder = ValidationRecorder.new(ValidationRecorderFormat.new.get_table(:simple_format)) }


    describe 'When presented with valid data' do
      let(:data) do
        [
            {one: false, two: false, three: 'bob', four: 1, five: 'rosebud'},
            {one: false, two: true, three: 'fred', four: 2, five: 'rosebud'},
            {one: true, two: false, three: 'mary', four: 3, five: 'rosebud'},
            {one: true, two: true, three: 'jane', four: 4, five: 'rosebud'},
        ]
      end

      before do
        line_number = 0
        data.each { |tuple| recorder.validate(line_number += 1, tuple) }
      end

      it 'should report no validation issues' do
        recorder.has_errors?.should be_false
      end

      it 'should report four rows processed' do
        recorder.rows_processed.should eq 4
      end
    end

    describe 'When presented with invalid data' do
      let(:data) do
        [
            {one: false, two: false, three: nil, four: 1, five: 'daisy'},
            {one: false, two: true, three: 'fred', four: 2, five: nil},
            {one: true, two: false, three: 'mary', four: 3, five: 'rosebud'},
            {one: true, two: true, three: 'jane', four: 4, five: 'rose'},
        ]
      end
      before do
        line_number = 0
        data.each { |tuple| recorder.validate(line_number += 1, tuple) }
      end

      it 'should report four rows processed' do
        recorder.rows_processed.should eq 4
      end

      it 'should report validation issues' do
        recorder.has_errors?.should be_true
      end

      it 'should report three errors encountered' do
        recorder.total_errors.should eq 3
      end

      it 'should report two errors on field five' do
        recorder.total_errors_for(:five).should eq 2
      end

      it 'should report one error on field three' do
        recorder.total_errors_for(:three).should eq 1
      end

      it 'report should be coherent' do
        report = recorder.report
        puts report
        report.should include('First line violating rule')
      end

    end

    describe 'Simple checks for test_validate' do
      let(:validator) {RequiredFieldValidator.new}

      it 'should provide nil report, but string inspect with no errors' do
        result = validator.test('bob')
        result.report.should be_nil
        result.inspect.should_not be_nil
        result.inspect.is_a?(String).should be_true
      end

      it 'should provide string report and inspect with errors' do
        result = validator.test(nil)
        result.report.should_not be_nil
        result.inspect.should_not be_nil
        result.report.is_a?(String).should be_true
        result.inspect.is_a?(String).should be_true

      end
    end

  end

end
