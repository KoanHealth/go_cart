require 'active_record'

module GoCart
class SchemaMigrator < ActiveRecord::Migration

	attr_accessor :schema

	def initialize(schema)
		super()
		@schema = schema
	end

	def up
		@schema.tables.each do |table_symbol, table|
			create_table table_symbol, table.get_options do |t|
				table.fields.each do |field_symbol, field|
					t.column field_symbol, field.type, field.get_options
				end
				t.timestamps if table.timestamps
			end
			table.indexes.each { |columns, options|
				add_index table_symbol, columns, options
			}
		end
	end

	def down
		@schema.tables.each do |table_symbol, table|
			drop_table table_symbol
		end
	end

end
end
