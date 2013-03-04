require 'csv'

module GoCart
  class LoaderFromCsv < Loader

    def self.foreach(file, format_table)
      filter = format_table.filter || ->(row) { true }

      symbol_map = {}
      raw_values = {}
      line_number = 0
      options = FileUtils.get_csv_options(file)
      CSV.foreach(file, options) do |row|
        raw_values.clear
        line_number += 1

        if options[:headers] && row.header_row?
          row.each do |raw_symbol, header|
            next if raw_symbol.nil?
            header = FileUtils.clean_string(header)
            field = format_table.get_field_by_header(header)
            raise "Unrecognized header: #{header}" if field.nil?
            symbol_map[raw_symbol] = field.symbol
          end
        elsif filter.call(row)
          if options[:headers]
            row.each do |raw_symbol, raw_value|
              next if raw_symbol.nil?
              symbol = symbol_map[raw_symbol]
              raw_values[symbol] = FileUtils.clean_string(raw_value)
            end
          else
            row.each_with_index do |raw_value, index|
              field = format_table.get_field_by_index(index+1)
              raw_values[field.symbol] = FileUtils.clean_string(raw_value)
            end
          end

          yield raw_values, line_number
        end
      end
    end
  end
end
