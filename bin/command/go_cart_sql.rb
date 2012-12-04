require_relative 'go_cart_def'

module GoCart
class GoCartSql < GoCartDef

	attr_accessor :from_format, :from_schema, :from_table, :to_format, :to_schema, :to_table

	def execute()
		require @from_format
		require @to_format

		from_schema = get_instance(@from_schema)
		to_schema = get_instance(@to_schema)

		from_table = from_schema.get_table(@from_table.to_sym)
		to_table = to_schema.get_table(@to_table.to_sym)

		template_directory = File.join(@script_dir, '../../templates')
		template = IO.read(File.join(template_directory, 'insert_select.sql.erb'))
		puts ERB.new(template).result(binding)
	end

	def setup_generator(generator)
		template_directory = File.join(@script_dir, '../../templates')
		generator.template_directory = template_directory
		generator.module_name = @module_name
		generator.class_name = @class_name
		return generator
	end

	def parse_options(opts)
		opts.banner = "Usage: #{$0} sql [OPTIONS] --from FORMATFILE --from_schema SCHEMACLASS --from_table TABLENAME --to FORMATFILE --to_schema SCHEMACLASS --to_table TABLENAME"
		opts.separator ''
		opts.separator 'Generates a sql insert statement from one table to another'
		opts.separator ''
		opts.separator 'OPTIONS:'

		opts.on('--from FORMATFILE', 'format filename') do |value|
			@from_format = value
		end

		opts.on('--from_schema SCHEMANAME', 'fully qualified schema classname') do |value|
			@from_schema = value
		end

		opts.on('--from_table TABLENAME', 'table name') do |value|
			@from_table = value
		end

		opts.on('--to FORMATFILE', 'format filename') do |value|
			@to_format = value
		end

		opts.on('--to_schema SCHEMANAME', 'fully qualified schema classname') do |value|
			@to_schema = value
		end

		opts.on('--to_table TABLENAME', 'table name') do |value|
			@to_table = value
		end

		parse_def_options opts

		# Verify arguments
	end

end
end