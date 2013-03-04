module GoCart
  class Validator
    attr_accessor :field

    Input = Struct.new(:line_number, :row, :field, :value)

    def failed(input)
      error_information.failed(input)
    end

    def get_error_information
      finalize_validation
      error_information
    end

    def finalize_validation
    end

    def test(value, field = nil, row = nil, line_number = 0)
      v = self.clone
      v.validate(Input.new(line_number, row, field, value))
      v.get_error_information
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

    def self.validate_group(group_count, evaluator)
      self.send :include, GroupValidator
      self.define_singleton_method(:group_validator_group_count) { group_count }
      case evaluator
        when Proc
          self.define_singleton_method(:group_validator_validate_group) {|gathered_items| evaluator.call(gathered_items) }
        when Symbol
          self.define_singleton_method(:group_validator_validate_group) {|gathered_items| send(evaluator, gathered_items) }
      end
    end

    def self.get(validator_symbol)
      clazz = classes.find { |c| c.validator_symbol == validator_symbol }
      raise "There is no registered validator named #{validator_symbol}.  Are you missing a require?" unless clazz
      clazz.new
    end



    private
    def self.inherited(validator_class)
      classes.push validator_class
    end

    def self.classes
      @classes ||= []
    end

    def error_information
      @error_information ||= ErrorInformation.new(self)
    end

  end
end
