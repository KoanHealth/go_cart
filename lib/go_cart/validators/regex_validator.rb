module GoCart
  class RegexValidator < Validator
    dont_register

    def initialize(expression, name = nil)
      @expression = expression
      @name = name
    end

    def name
      @name || super
    end

    def validate(input)
      failed(input) unless @expression =~ input.value.to_s
    end
  end
end
