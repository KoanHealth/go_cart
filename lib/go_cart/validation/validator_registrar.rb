module GoCart
  class ValidatorRegistrar

    def self.get_validator(data_symbol, validator_symbol)
      key = [data_symbol, validator_symbol]
      instances.fetch(key) do
        clazz = classes.find { |c| c.validator_symbol == validator_symbol }
        raise "There is no registered validator named #{validator_symbol}.  Are you missing a require?" unless clazz
        instances[key] = clazz.new
      end
    end

    def self.register_validator_class(validator_class)
      classes.push validator_class
    end

    private
    def self.instances
      @instances ||= {}
    end

    def self.classes
      @classes ||= []
    end
  end

end
