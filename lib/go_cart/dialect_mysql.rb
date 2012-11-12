module GoCart
class DialectMySql

	def prepare_row(row)
      # MySql requires \N to differentiate NULL from empty
      return row.map { |field| field.nil? ? "\\N" : field }
	end

	def generate_command(schema_table, table_name, filename)
		field_separator = "\\t"
		columns = schema_table.get_columns()

		return <<-END_OF_QUERY
			LOAD DATA INFILE '#{filename}'
			INTO TABLE #{table_name}
			FIELDS TERMINATED BY '#{field_separator}'
			IGNORE 1 LINES (
			#{columns.map { |symbol| "`#{symbol}`" }.join(',')}
			)
		END_OF_QUERY
	end

end
end
