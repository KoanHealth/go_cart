module GoCart
class DialectPostgresql

	def initialize(field_separator = "\t")
		@field_separator = field_separator
	end

	def prepare_row(row)
		# In PostgreSQL CSV empty is NULL
		return row
	end

	def load_from_file(connection, schema_table, table_name, filename)
		raw_connection = connection.raw_connection
		sql_cmd = generate_load_command(schema_table, table_name)
		raw_connection.exec sql_cmd

		File.readlines(filename).each do |line|
			raw_connection.put_copy_data line
		end
		raw_connection.put_copy_end

		# pump out the result stream
		while result = raw_connection.get_result do
			result.check_result
		end
	end

	def save_to_file(connection, schema_table, table_name, filename, options = {})
		raw_connection = connection.raw_connection
		sql_cmd = generate_save_command(schema_table, table_name, options)
		result = raw_connection.exec sql_cmd

		File.open(filename, 'w') do |file|
			while (row = raw_connection.get_copy_data())
				file.puts(row)
			end
		end

		result.clear()
	end

private

	def generate_load_command(schema_table, table_name)
		columns = schema_table.get_columns()
		e_field = 'E' if @field_separator.ord < 32
		delimiter = @field_separator.inspect[1..-2]

		return <<-END_OF_QUERY
			COPY #{table_name} (
			#{columns.map { |symbol| "\"#{symbol}\"" }.join(',')}
			) FROM STDIN
			WITH DELIMITER #{e_field}'#{delimiter}' CSV HEADER;
		END_OF_QUERY
	end

	def generate_save_command(schema_table, table_name, options = {})
		columns = schema_table.get_columns()
		e_field = 'E' if @field_separator.ord < 32
		delimiter = @field_separator.inspect[1..-2]

		order_by = get_order_by(options)
		if order_by.nil?
			return <<-END_OF_QUERY
				COPY #{table_name} (
				#{columns.map { |symbol| "\"#{symbol}\"" }.join(',')}
				) TO STDOUT
				WITH DELIMITER #{e_field}'#{delimiter}' CSV HEADER;
			END_OF_QUERY
		else
			return <<-END_OF_QUERY
				COPY ( SELECT
				#{columns.map { |symbol| "\"#{symbol}\"" }.join(',')}
				FROM #{table_name}#{order_by}
				) TO STDOUT
				WITH DELIMITER #{e_field}'#{delimiter}' CSV HEADER;
			END_OF_QUERY
		end
	end

	def get_order_by(options)
		order = options[:order_by]
		return nil if order.nil? || order.empty?

		suffix = []
		order.each do |column, direction|
			sql_dir = (direction == :desc ? 'DESC' : 'ASC')
			suffix << "#{column} #{sql_dir}"
		end
		return ' ORDER BY ' + suffix.join(',')
	end

end
end
