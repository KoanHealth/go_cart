require 'spec_helper'

module GoCart
  module Errors
    describe GoCartError do

      it 'should format options' do
        info = {foo: 'bar', something: 'interesting'}
        GoCartError.new.format_options(info).should eq "foo: \"bar\", something: \"interesting\""
      end

      it 'should format a message' do
        info = {foo: 'bar', something: 'interesting'}
        GoCartError.new.format_message('FAIL', info).should eq "FAIL foo: \"bar\", something: \"interesting\""
      end

      it 'should format a message with nil options' do
        GoCartError.new.format_message('FAIL', nil).should eq 'FAIL'
      end

    end
  end
end
