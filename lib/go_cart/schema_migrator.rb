require 'active_record'

module GoCart
class SchemaMigrator < ActiveRecord::Migration

	attr_accessor :schema, :suffix

	def initialize(schema, suffix = nil)
		super()
		@schema = schema
		@suffix = suffix
	end

	def up
		@schema.tables.each do |table_symbol, table|
			create_table get_table_symbol(table_symbol), table.get_options do |t|
				table.fields.each do |field_symbol, field|
					t.column field_symbol, field.type, field.get_options
				end
				t.timestamps if table.timestamps
			end
			table.indexes.each { |columns, options|
				add_index get_table_symbol(table_symbol), columns, options
			}
		end
	end

	def down
		@schema.tables.each do |table_symbol, table|
			drop_table get_table_symbol(table_symbol)
		end
	end

private

	def get_table_symbol(symbol)
		return @suffix.nil? ? symbol : (symbol.to_s + @suffix).to_sym
	end

end
end
