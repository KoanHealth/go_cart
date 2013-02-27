module GoCart
  class LoaderFromFixed < Loader

    def load(file, format_table)
      filter = format_table.filter

      line_number = 0
      File.open(file, 'r').each do |line|
        next if line =~ /^\s*$/
        line.chomp!
        line_number += 1

        unless filter.nil?
          next unless filter.call(line)
        end

        raw_values = {}
        format_table.fields.each do |symbol, field|
          raw_values[symbol] = field.get_raw_value(line)
        end

        yield raw_values, line_number
      end
    end
  end
end
