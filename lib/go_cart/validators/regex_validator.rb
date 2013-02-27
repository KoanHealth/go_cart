module GoCart
  class RegexValidator < Validator
    dont_register

    def initialize(expression, message = nil)
      @expression = expression
      @message = message
    end

    def message
      @message || 'Did not match expected pattern'
    end

    def validate(input)
      failed(input, message) unless @expression =~ input.value
    end
  end
end
