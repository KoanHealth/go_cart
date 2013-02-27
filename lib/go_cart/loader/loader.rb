module GoCart
  class Loader
    class RawTableConverter
      attr_reader :format_table

      def initialize(format_table)
        @format_table = format_table
      end
    end

    def convert_raw_values(row)
      {}.tap do |values|
        row.each do |raw_symbol, raw_value|
          next if raw_symbol.nil?
          symbol = symbol_map[raw_symbol]
          format_field = format_table.fields[symbol]
          values[symbol] = format_field.extract_value(raw_value)
        end
      end
    end

    # TBD

  end
end
