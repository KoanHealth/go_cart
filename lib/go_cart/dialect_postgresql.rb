module GoCart
class DialectPostgresql

	def prepare_row(row)
      # In PostgreSQL CSV empty is NULL
      return row
	end

	def generate_command(schema_table, filename)
		table_name = schema_table.symbol
		field_separator = "\\t"
		columns = schema_table.get_columns()

		return <<-END_OF_QUERY
			COPY #{table_name} (
			#{columns.map { |symbol| "\"#{symbol}\"" }.join(',')}
			) FROM '#{filename}'
			WITH DELIMITER E'#{field_separator}' CSV HEADER
		END_OF_QUERY
	end

end
end
