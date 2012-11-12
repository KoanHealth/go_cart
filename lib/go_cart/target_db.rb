require 'active_record'

module GoCart
class TargetDb < Target

	BATCH_SIZE = 100

	attr_accessor :dbconfig

	def initialize(dbconfig)
		@dbconfig = dbconfig
		@table_class = nil
		@rows_data = []
		@columns = nil
	end

	def open(mapper, schema_table)
		open_database_connection @dbconfig
		@table_class = create_activerecord_class schema_table.symbol
		unless ActiveRecord::Base.connection.table_exists? @table_class.table_name
			create_tables mapper
		end
		@columns = schema_table.get_columns()
	end

	def emit(row)
		@rows_data << row
		flush_rows
	end

	def close()
		begin
			flush_rows 0
		ensure
			close_database_connection
		end
	end

private

	def flush_rows(size = BATCH_SIZE)
		if @rows_data.size > size
			@table_class.import @columns, @rows_data
			@rows_data = []
		end
	end

end
end
