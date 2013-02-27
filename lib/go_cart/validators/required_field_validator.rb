module GoCart

class RequiredFieldValidator < Validator

  def validate(input)
    failed(input, 'value was not present') if input.value.to_s.empty?
  end
end
end
