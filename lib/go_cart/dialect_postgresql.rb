module GoCart
class DialectPostgresql

	def prepare_row(row)
      # In PostgreSQL CSV empty is NULL
      return row
	end

	def execute_command(connection, schema_table, table_name, filename)
		raw_connection = connection.raw_connection
		raw_connection.exec generate_command(schema_table, table_name)

		file = File.new filename
		file.each do |line|
			raw_connection.put_copy_data line
		end
		raw_connection.put_copy_end

		# pump down the result stream (apparently, this is important)
		while raw_connection.get_result do end
	end

	def generate_command(schema_table, table_name)
		field_separator = "\\t"
		columns = schema_table.get_columns()

		return <<-END_OF_QUERY
			COPY #{table_name} (
			#{columns.map { |symbol| "\"#{symbol}\"" }.join(',')}
			) FROM STDIN
			WITH DELIMITER E'#{field_separator}' CSV HEADER
		END_OF_QUERY
	end

end
end
