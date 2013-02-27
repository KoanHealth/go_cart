require 'spec_helper'

module GoCart

  describe ValidationRecorder do
    class SimpleFormat < GoCart::Format
      def initialize
        super
        create_table :simple_format, :headers => true, :name => 'simple_format' do |t|
          t.boolean :one, header: :one
          t.boolean :two, header: :two
          t.string :three, header: :three, :validation => :required_field
          t.integer :four, header: :four
          t.string :five, header: :five, :validation => RegexValidator.new(/^rose(bud)?$/, 'your flower stinks')
        end
      end
    end

    let(:recorder) { recorder = ValidationRecorder.new(SimpleFormat.new.get_table(:simple_format)) }

    describe 'When presented with valid data' do
      let(:data) do
        [
            {one: false, two: false, three: 'bob', four: 1, five: 'rosebud'},
            {one: false, two: true, three: 'fred', four: 2, five: 'rosebud'},
            {one: true, two: false, three: 'mary', four: 3, five: 'rosebud'},
            {one: true, two: true, three: 'jane', four: 4, five: 'rosebud'},
        ]
      end

      it 'should report no validation issues' do
        data.each { |tuple| recorder.validate(tuple) }
        recorder.has_errors?.should be_false
      end

      it 'should report four rows processed' do
        data.each { |tuple| recorder.validate(tuple) }
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
        data.each { |tuple| recorder.validate(tuple) }
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
        recorder.errors_for(:five).count.should eq 2
      end

      it 'should report one error on field three' do
        recorder.errors_for(:three).count.should eq 1
      end
    end

  end

end
