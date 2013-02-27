module GoCart

  # given a format file and a set of data tuples, this class will report on all of the violations
  # of the rules specified in the format file
  class ValidationRecorder
    attr_reader :rows_processed, :format

    def initialize(format, options = {})
      @format = format
      @options = options
      @rows_processed = 0
    end

    def validate(tuple)
      tuple.each { |symbol, value| validate_value(tuple, symbol, value) }
      @rows_processed += 1
    end

    def has_errors?
      total_errors > 0
    end

    def total_errors
      errors.count
    end

    private
    def validate_value(tuple, symbol, value)
      get_validators(symbol).each do |v|
        result = v.validate(tuple, symbol, value)
        errors.push result if result
      end
    end

    def get_validators(symbol)
      validators.fetch(symbol) do
        field = format.get_field(symbol)
        field_validators = [field.validation].flatten.map do |v|
          next unless v
          case v
            when Symbol
              ValidatorRegistrar.get_validator(symbol, v)
            when Proc
              v.call
            else
              v.clone
          end
        end.compact
        validators[symbol] = field_validators
      end
    end

    def validators
      @validators ||= {}
    end

    def errors
      @errors ||= []
    end


  end
end
