require 'active_record'

module GoCart
class SchemaMigrator

	attr_accessor :schema, :suffix

	def initialize(schema, suffix = nil)
		@schema = schema
		@suffix = suffix
	end

	def up
		@schema.tables.each do |table_symbol, table|
			Schema_Table_Migrator.new(table, @suffix).up
		end
	end

	def down
		@schema.tables.each do |table_symbol, table|
			Schema_Table_Migrator.new(table, @suffix).down
		end
	end

end
end
