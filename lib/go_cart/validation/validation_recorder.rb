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
      error_information.any? { |ei| ei.has_errors? }
    end

    def total_errors
      error_information.reduce(0) do |total, ei|
        total += ei.failed_lines
      end
    end

    def error_information_for(field)
      validators[field].map { |v| v.get_error_information }
    end

    def total_errors_for(field)
      validators[field].map { |v| v.get_error_information }.reduce(0) do |total, ei|
        total += ei.failed_lines
      end
    end

    def report
      <<-END
Validation Performed on #{rows_processed} rows.
#{total_errors} errors found
#{'DETAILS'.center(80, '=')}
      #{error_information.map { |ei| ei.report(rows_processed) }.compact.join(''.center(80, '-') + "\n")}
      END
    end

    private
    def validate_value(input)
      get_validators(input.field).each do |v|
        v.validate(input)
      end
    end

    def get_validators(field_symbol)
      validators.fetch(field_symbol) do
        field = format.get_field(field_symbol)
        if field
          field_validators = [field.validation].flatten.map do |v|
            next unless v
            case v
              when Symbol
                Validator.get(v)
              else
                v.clone
            end
          end.compact
          field_validators.each { |v| v.field = field_symbol }
        else
          field_validators = []
        end

        validators[field_symbol] = field_validators
      end
    end

    def validators
      @validators ||= {}
    end

    def error_information
      validators.values.map do |validator_array|
        validator_array.map { |v| v.get_error_information }.flatten
      end.flatten
    end


  end
end
