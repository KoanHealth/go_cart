require 'spec_helper'

module GoCart
  describe FormatField do

    let (:line) { 'The quick brown fox jumps over the lazy dog' }

    context 'get_raw_value' do

      it 'works with start and length' do
        field = FormatField.new(:some_field, :string, start: 5, length: 5)
        field.get_raw_value(line).should eq line[4..8]
      end

      it 'works with start and end' do
        field = FormatField.new(:some_field, :string, start: 5, end: 9)
        field.get_raw_value(line).should eq line[4..8]
      end

    end

  end
end