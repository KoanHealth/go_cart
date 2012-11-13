require 'csv'

module GoCart
class TargetFile < Target

	BATCH_SIZE = 100

	attr_accessor :dialect, :filename

	def initialize(dialect, filename)
    @dialect = dialect
		@filename = File.expand_path(filename)
		@rows_data = []
		@writer = nil
	end

	def open(mapper, schema_table)
		@writer = CSV.open(@filename, 'w', { :col_sep => "\t" })
		@writer << schema_table.get_columns()
	end

	def emit(row)
		@rows_data << row
		flush_rows
	end

	def close()
		begin
			flush_rows 0
		ensure
			@writer.close
		end
	end

	def import(dbconfig, mapper, schema_table)
		open_database_connection dbconfig
		begin
			table_name = get_table_name(schema_table.symbol)
			unless ActiveRecord::Base.connection.table_exists? table_name
				create_tables mapper
			end
			@dialect.execute_command(ActiveRecord::Base.connection, schema_table, table_name, @filename)
		ensure
			close_database_connection
		end
	end

	def delete
		unless @filename.nil?
			File.delete @filename
			@filename = nil
		end
	end

private

	def flush_rows(size = BATCH_SIZE)
		if @rows_data.size > size
			@rows_data.each { |row| @writer << @dialect.prepare_row(row) }
			@rows_data = []
		end
	end

end
end
