require 'active_record'
require 'activerecord-import'

module GoCart
class Target

	attr_accessor :suffix, :schema

	def get_table_name(symbol)
		return @suffix.nil? ? symbol : (symbol.to_s + @suffix).to_sym
	end

	def execute(dbconfig, sql_script)
		open_database_connection dbconfig
		begin
			return ActiveRecord::Base.connection.execute sql_script
		ensure
			close_database_connection
		end
	end

	def save_table(dbconfig, dialect, schema_table, filename)
		open_database_connection dbconfig
		begin
			table_name = get_table_name(schema_table.symbol)
			dialect.save_to_file(ActiveRecord::Base.connection, schema_table, table_name, filename)
		ensure
			close_database_connection
		end
	end

	def drop_db_schema(dbconfig, dialect, schema_name)
		ActiveRecord::Base.establish_connection(dbconfig)
		begin
			# TODO: Move to dialect, this is Postgresql specific
			if ActiveRecord::Base.connection.schema_exists?(schema_name)
				ActiveRecord::Base.connection.execute "DROP SCHEMA #{schema_name} CASCADE;"
			end
		ensure
			ActiveRecord::Base.connection.disconnect!
		end
	end

	def open_database_connection(dbconfig)
		ActiveRecord::Base.establish_connection(dbconfig)
		unless @schema.nil?
			# TODO: Move to dialect, this is Postgresql specific
			unless ActiveRecord::Base.connection.schema_exists?(@schema)
				ActiveRecord::Base.connection.execute "CREATE SCHEMA #{@schema};"
			end
			ActiveRecord::Base.connection.schema_search_path = "#{@schema},public"
		end
	end

	def create_database(dbconfig)
		ActiveRecord::Base.connection.create_database(dbconfig['database'])
	end

	def create_tables(schema)
		migrator = SchemaMigrator.new schema, @suffix
		migrator.up
	end

	def create_activerecord_class(table_name)
		table_name = get_table_name(table_name)
		Class.new(ActiveRecord::Base) do
			self.table_name = table_name
		end  
	end

	def drop_tables(schema)
		migrator = SchemaMigrator.new schema, @suffix
		migrator.down
	end

	def drop_database(dbconfig, ignore_error = true)
		begin
			ActiveRecord::Base.connection.drop_database(dbconfig['database'])
		rescue
			raise unless ignore_error
		end
	end

	def close_database_connection
		ActiveRecord::Base.connection.disconnect!
	end

end
end
