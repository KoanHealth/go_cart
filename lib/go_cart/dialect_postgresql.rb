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
		raw_connection.exec generate_load_command(schema_table, table_name)

		File.readlines(filename).each do |line|
			raw_connection.put_copy_data line
		end
		raw_connection.put_copy_end

		# pump out the result stream
		while raw_connection.get_result do end
	end

	def save_to_file(connection, schema_table, table_name, filename)
		raw_connection = connection.raw_connection
		result = raw_connection.exec generate_save_command(schema_table, table_name)

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

		return <<-END_OF_QUERY
			COPY #{table_name} (
			#{columns.map { |symbol| "\"#{symbol}\"" }.join(',')}
			) FROM STDIN
			WITH DELIMITER E'#{@field_separator}' CSV HEADER
		END_OF_QUERY
	end

	def generate_save_command(schema_table, table_name)
		columns = schema_table.get_columns()

		return <<-END_OF_QUERY
			COPY #{table_name} (
			#{columns.map { |symbol| "\"#{symbol}\"" }.join(',')}
			) TO STDOUT
			WITH DELIMITER E'#{@field_separator}' CSV HEADER
		END_OF_QUERY
	end

end
end
