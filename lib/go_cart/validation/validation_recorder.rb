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

    def validate(line_number, tuple)
      input = Validator::Input.new(line_number, tuple)
      tuple.each do |symbol, value|
        input.field = symbol
        input.value = value
        validate_value(input)
      end
      @rows_processed += 1
    end

    def has_errors?
      total_errors > 0
    end

    def total_errors
      errors.count
    end

    def errors_for(field)
      errors.select {|e| e.field == field}
    end

    def rows_with_errors
      error_count = Hash.new(0)
      errors.each { |e| error_count[e.line_number] += 1 }
      error_count.count
    end

    private
    def validate_value(input)
      get_validators(input.field).each do |v|
        result = v.validate(input)
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
              Validator.get(symbol, v)
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
