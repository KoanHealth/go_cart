require 'active_record'
require 'activerecord-import'

module GoCart
class Target

	attr_accessor :db_suffix, :db_schema

	def get_table_name(symbol)
		return @db_suffix.nil? ? symbol : (symbol.to_s + @db_suffix).to_sym
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
		unless @db_schema.nil?
			# TODO: Move to dialect, this is Postgresql specific
			unless ActiveRecord::Base.connection.schema_exists?(@db_schema)
				ActiveRecord::Base.connection.execute "CREATE SCHEMA #{@db_schema};"
			end
			ActiveRecord::Base.connection.schema_search_path = "#{@db_schema},public"
		end
	end

	def create_database(dbconfig)
		ActiveRecord::Base.connection.create_database(dbconfig['database'])
	end

	def create_table(schema_table)
		SchemaTableMigrator.new(schema_table, @db_suffix).up
	end

	def create_tables(schema)
		SchemaMigrator.new(schema, @db_suffix).up
	end

	def create_activerecord_class(table_name)
		table_name = get_table_name(table_name)
		Class.new(ActiveRecord::Base) do
			self.table_name = table_name
		end  
	end

	def drop_table(schema_table)
		SchemaTableMigrator.new(schema_table, @db_suffix).down
	end

	def drop_tables(schema)
		SchemaMigrator.new(schema, @db_suffix).down
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
