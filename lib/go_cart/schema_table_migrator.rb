require 'active_record'

module GoCart
class SchemaTableMigrator < ActiveRecord::Migration

	attr_accessor :schema_table, :suffix

	def initialize(schema_table, suffix = nil)
		super()
		@schema_table = schema_table
		@suffix = suffix
	end

	def up
		table_symbol = get_table_symbol
		create_table table_symbol, @schema_table.get_options do |t|
			@schema_table.fields.each do |field_symbol, field|
				t.column field_symbol, field.type, field.get_options
			end
			t.timestamps if @schema_table.timestamps
		end
		@schema_table.indexes.each { |columns, options|
			add_index table_symbol, columns, options
		}
	end

	def down
		drop_table get_table_symbol
	end

private

	def get_table_symbol
		symbol = @schema_table.symbol
		return @suffix.nil? ? symbol : (symbol.to_s + @suffix).to_sym
	end

end
end
