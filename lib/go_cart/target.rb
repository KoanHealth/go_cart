require 'active_record'
require 'activerecord-import'
#require 'logger'

module GoCart
class Target

	attr_accessor :suffix, :schema

	def get_table_name(symbol)
		return @suffix.nil? ? symbol : (symbol.to_s + @suffix).to_sym
	end

	def open_database_connection(dbconfig)
		ActiveRecord::Base.establish_connection(dbconfig)
		#ActiveRecord::Base.logger = Logger.new(STDERR)
		unless @schema.nil?
			unless ActiveRecord::Base.connection.schema_exists?(@schema)
				ActiveRecord::Base.connection.execute "CREATE SCHEMA #{@schema};"
				# CREATE SCHEMA #{@schema};
				# SET search_path TO #{@schema};
				# DROP SCHEMA #{@schema} CASCADE;
			end
			ActiveRecord::Base.connection.schema_search_path = "#{@schema},public"
		end
	end

	def create_database(dbconfig)
		ActiveRecord::Base.connection.create_database(dbconfig['database'])
	end

	def create_tables(mapper)
		migrator = SchemaMigrator.new mapper.schema, @suffix
		migrator.up
	end

	def create_activerecord_class table_name
		full_table_name = get_table_name(table_name)
		Class.new(ActiveRecord::Base) do
			self.table_name = full_table_name
		end  
	end

	def drop_tables(mapper)
		migrator = SchemaMigrator.new mapper.schema, @suffix
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
