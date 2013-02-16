require 'spec_helper'

module GoCart
  module Errors
    describe LoaderError do

      it 'message should include correct information' do
        LoaderError.new('tmp/file', 42, StandardError.new('WTF')).message.should eq "Loader failed file: \"tmp/file\", line: 42, error: \"WTF\""
      end

    end
  end
end
