require 'rubygems'
require 'active_record'
require 'activerecord-import'
require 'logger'

module GoCart
class Target

	# TBD

protected

	def open_database_connection(dbconfig)
		ActiveRecord::Base.establish_connection(dbconfig)
		ActiveRecord::Base.logger = Logger.new(STDERR) if @verbose
	end

	def create_database(dbconfig)
		ActiveRecord::Base.connection.create_database(dbconfig['database'])
	end

	def create_tables(mapper)
		migrator = SchemaMigrator.new mapper.schema
		migrator.up
	end

	def create_activerecord_class table_name  
		Class.new(ActiveRecord::Base) do
			self.table_name = table_name
		end  
	end

	def drop_tables(mapper)
		migrator = SchemaMigrator.new mapper.schema
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
