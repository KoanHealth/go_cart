module GoCart
  class Validator
    Error = Struct.new(:validator, :field, :value, :explanation)

    def failed(field, value, explanation)
      Error.new(self, field, value, explanation)
    end

    def symbol;
      self.class.validator_symbol
    end

    def name;
      self.class.validator_name
    end

    def self.validator_symbol
      ActiveSupport::Inflector.underscore(self.name.split('::').last.gsub('Validator', '')).to_sym
    end

    def self.validator_name
      ActiveSupport::Inflector.humanize(validator_symbol.to_s)
    end

    def Validator.identify_as(symbol, name)
      self.define_singleton_method(:validator_symbol) { symbol }
      self.define_singleton_method(:validator_name) { name }
    end

    def self.dont_register
      Validator.classes.delete(self)
    end

    def self.get(data_symbol, validator_symbol)
      key = [data_symbol, validator_symbol]
      instances.fetch(key) do
        clazz = classes.find { |c| c.validator_symbol == validator_symbol }
        raise "There is no registered validator named #{validator_symbol}.  Are you missing a require?" unless clazz
        instances[key] = clazz.new
      end
    end

    private
    def self.inherited(validator_class)
      classes.push validator_class
    end

    def self.instances
      @instances ||= {}
    end

    def self.classes
      @classes ||= []
    end


  end
end
