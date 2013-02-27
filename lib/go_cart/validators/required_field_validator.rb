module GoCart

class RequiredFieldValidator < Validator
  register

  def validate(tuple, symbol, value)
    failed(symbol, value, 'value was not present') if value.to_s.empty?
  end
end
end
