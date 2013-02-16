require 'spec_helper'
require 'ostruct'

module GoCart
  module Errors
    describe MappingError do

      it 'message should include correct information' do
        field = OpenStruct.new(symbol: :field1)
        MappingError.new(field, StandardError.new('WTF')).message.should eq "Mapping failed field: :field1, error: \"WTF\""
      end

    end
  end
end
