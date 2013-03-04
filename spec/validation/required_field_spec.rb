require 'spec_helper'

module GoCart
  describe RequiredFieldValidator do
    let(:validator) {RequiredFieldValidator.new}

    it 'should not have errors with valid input' do
      result = validator.test ('bob')
      result.should be
      result.has_errors?.should be_false
    end

    it 'should have errors with invalid input' do
      result = validator.test (nil)
      result.should be
      result.has_errors?.should be_true
    end


  end
end
