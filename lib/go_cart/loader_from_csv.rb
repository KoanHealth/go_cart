require 'csv'

module GoCart
class LoaderFromCsv < Loader

	def load(file, mapper, format_table, schema_table, target)
		target.open mapper.schema, schema_table
		begin
			filter = format_table.filter
			mapping = mapper.get_mapping schema_table.symbol

			symbol_map = {}
			raw_values = {}
			options = FileUtils.get_csv_options(file)
			CSV.foreach(file, options) do |row|
				raw_values.clear
				if options[:headers]
					if row.header_row?
						row.each do |raw_symbol, header|
							next if raw_symbol.nil?
							field = format_table.get_field_by_header(header)
							raise "Unrecognized field header: #{header}" if field.nil?
							symbol_map[raw_symbol] = field.symbol
						end
						next
					end

					unless filter.nil?
						next unless filter.call(row)
					end
					row.each do |raw_symbol, raw_value|
						next if raw_symbol.nil?
						symbol = symbol_map[raw_symbol]
						raw_values[symbol] = raw_value
					end
				else
					unless filter.nil?
						next unless filter.call(row)
					end
					row.each_with_index do |raw_value, index|
						field = format_table.get_field_by_index(index+1)
						raw_values[field.symbol] = raw_value
					end
				end
				
				field_data = mapping.map_fields(raw_values)
				target.emit field_data unless field_data.nil?
			end
		ensure
			target.close
		end
	end

end
end
