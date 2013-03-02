module GoCart

class RequiredFieldValidator < Validator

  def validate(input)
    failed(input) if input.value.to_s.empty?
  end
end
end
