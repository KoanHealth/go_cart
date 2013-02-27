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

    def validate(tuple, symbol, value)
      failed(symbol, value, message) unless @expression =~ value
    end
  end
end
