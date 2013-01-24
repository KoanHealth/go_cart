require 'csv'

module GoCart
  class CsvLoader
    include Enumerable

    def initialize(file_name, format_table)
      @file_name = file_name
      @format_table = format_table
    end

    def each
      CSV.foreach(@file_name, options) do |row|
        if @options[:headers] && row.header_row?
          @symbol_map = extract_headers row, @format_table
          next
        end

        next unless filter.nil? || filter.call(row)

        yield options[:headers] ?
            process_row_with_header(row, @format_table, @symbol_map) :
            process_row_with_index(row, @format_table)
      end
    end

    private
    def filter
      @format_table.filter
    end

    def options
      @options ||= FileUtils.get_csv_options(@file_name)
    end

    def extract_headers(row, format_table)
      symbol_map = {}
      row.each do |raw_symbol, header|
        next if raw_symbol.nil?
        field = format_table.get_field_by_header(header)
        raise "Unrecognized header: #{header}" if field.nil?
        symbol_map[raw_symbol] = field.symbol
      end
      return symbol_map
    end

    def process_row_with_header(row, format_table, symbol_map)
      values = {}

      row.each do |raw_symbol, raw_value|
        next if raw_symbol.nil?
        symbol = symbol_map[raw_symbol]
        format_field = format_table.fields[symbol]
        values[symbol] = format_field.extract_value(raw_value)
      end

      return values
    end

    def process_row_with_index(row, format_table)
      values = {}

      row.each_with_index do |raw_value, index|
        format_field = format_table.get_field_by_index(index+1)
        values[format_field.symbol] = format_field.extract_value(raw_value)
      end

      return values
    end
  end
end
