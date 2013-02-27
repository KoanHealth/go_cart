module GoCart
  class Validator
    def failed(symbol, value, explanation)
      [self.class, symbol, value, explanation]
    end

    def symbol;
      self.class.validator_symbol
    end

    def name;
      self.class.validator_name
    end

    # Default identification for validators: A class called RequiredFieldValidator would become
    # :required_field/'Required Field'.  If you don't like those defaults, you can easily change them
    # by calling the identify_as() method in your derived class declaration
    def self.validator_symbol
      ActiveSupport::Inflector.underscore(self.name.split('::').last.gsub('Validator', '')).to_sym
    end

    def self.validator_name
      ActiveSupport::Inflector.humanize(validator_symbol.to_s)
    end

    def self.identify_as(symbol, name)
      self.define_singleton_method(:validator_symbol) { symbol }
      self.define_singleton_method(:validator_name) { name }
    end

    def self.register
      ValidatorRegistrar.register_validator_class self
    end

  end
end
