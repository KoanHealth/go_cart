module GoCart
class LoaderFromFixed < Loader

	def load(file, mapper, format_table, schema_table, target)
		target.open schema_table
		begin
			filter = format_table.filter
			mapping = mapper.get_mapping schema_table.symbol

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

        begin
				  field_data = mapping.map_fields(raw_values)
        rescue Exception => e
          raise GoCart::Errors::LoaderError.new(file, line_number, e)
        end
				target.emit field_data unless field_data.nil?
			end
		ensure
			target.close
		end
	end

end
end
