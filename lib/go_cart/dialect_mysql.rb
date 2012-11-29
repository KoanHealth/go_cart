module GoCart
class DialectMySql

	def initialize(field_separator = "\t")
		@field_separator = field_separator
	end

	def prepare_row(row)
      # MySql requires \N to differentiate NULL from empty
      return row.map { |field| field.nil? ? "\\N" : field }
	end

	def load_from_file(connection, schema_table, table_name, filename)
		connection.execute generate_load_command(schema_table, table_name, filename)
	end

	def save_to_file(connection, schema_table, table_name, filename)
		connection.execute generate_save_command(schema_table, table_name, filename)
	end

private

	def generate_load_command(schema_table, table_name, filename)
		columns = schema_table.get_columns()
		delimiter = @field_separator.inspect[1..-2]

		return <<-END_OF_QUERY
			LOAD DATA INFILE '#{filename}'
			INTO TABLE #{table_name}
			FIELDS TERMINATED BY '#{delimiter}'
			IGNORE 1 LINES (
			#{columns.map { |symbol| "`#{symbol}`" }.join(',')}
			)
		END_OF_QUERY
	end

	def generate_save_command(schema_table, table_name, filename)
		columns = schema_table.get_columns()
		delimiter = @field_separator.inspect[1..-2]

		return <<-END_OF_QUERY
			SELECT #{columns.map { |symbol| "`#{symbol}`" }.join(',')}
			INTO OUTFILE '#{filename}'
			FIELDS TERMINATED BY '#{delimiter}'
			FROM #{table_name}
		END_OF_QUERY
	end

end
end
