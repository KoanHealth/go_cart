module GoCart
  class RawTableConverter
    attr_reader :format_table

    def initialize(format_table)
      @format_table = format_table
    end

    def convert(row)
      {}.tap do |values|
        row.each do |symbol, raw_value|
          next if symbol.nil?
          format_field = format_table.fields[symbol]
          values[symbol] = format_field.extract_value(raw_value)
        end
      end
    end

  end
end
