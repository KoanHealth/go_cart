require 'csv'

module GoCart
class Generator

	attr_accessor :template_directory, :module_name, :class_name

	def initialize()
		@formats = {}
		@current_format = nil
		@current_format_table = nil

		@schemas = {}
		@current_schema = nil
		@current_schema_table = nil

		@current_fields = {}
	end

protected

	FORMAT_FIELDS = [ 'symbol', 'type', 'header', 'index', 'start', 'end', 'length', 'name', 'description' ]
	SCHEMA_FIELDS = [ 'symbol', 'type', 'limit', 'null', 'default', 'precision', 'scale' ]
	ALLOWED_FIELDS = FORMAT_FIELDS | SCHEMA_FIELDS | [ 'ignore' ]

	def define_module(name)
		@module_name = TypeUtils.to_class_name(name)
	end

	def define_format(name)
		define_module(name) if @module_name.nil?
		symbol = TypeUtils.to_symbol(name)

		raise "Duplicate format: #{name}" unless @formats[symbol].nil?

		@formats[symbol] = @current_format = Format.new(name)
		@schemas[symbol] = @current_schema = Schema.new(name)
	end

	def define_table(name)
		define_format("My Format") if @current_format.nil?
		symbol = TypeUtils.to_symbol(name)

		@current_format_table = FormatTable.new(symbol)
		@current_format_table.name = name
		@current_format.add_table(@current_format_table)

		@current_schema_table = SchemaTable.new(symbol)
		@current_schema.add_table(@current_schema_table)
	end

	def define_fields(names)
		define_table("My Table") if @current_format_table.nil?

		@current_fields.clear
		names = names.split(',').map { |v| v.strip.downcase }
		names.each_with_index do |name, index|
			raise "Unrecognized field: #{name}" unless ALLOWED_FIELDS.include?(name)
			@current_fields[name] = index
		end
	end

	def add_new_field(symbol, type, options = {})
		field = FormatField.new(symbol, type,
			options.reject { |k,v| !FORMAT_FIELDS.include? k.to_s })
		@current_format_table.add_field field

		field = SchemaField.new(symbol, type,
			options.reject { |k,v| !SCHEMA_FIELDS.include? k.to_s })
		@current_schema_table.add_field field
	end

end
end
