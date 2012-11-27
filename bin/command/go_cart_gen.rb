require_relative 'go_cart_def'

module GoCart
class GoCartGen < GoCartDef

	attr_accessor :data_file, :schema_file, :format_file, :module_name, :class_name

	def execute()
		unless @schema_file.nil?
			generator = setup_generator GeneratorFromSchema.new
			generator.generate @schema_file, @format_file
		end
		unless @data_file.nil?
			generator = setup_generator GeneratorFromData.new
			generator.generate @data_file, @format_file
		end
	end

	def setup_generator(generator)
		template_directory = File.join(@script_dir, '../../templates')
		generator.template_directory = template_directory
		generator.module_name = @module_name
		generator.class_name = @class_name
		return generator
	end

	def parse_options(opts)
		opts.banner = "Usage: #{$0} gen [OPTIONS] [--data DATAFILE] [--schema SCHEMAFILE] --format FORMATFILE"
		opts.separator ''
		opts.separator 'Generates a format file for the specified schema or data file'
		opts.separator ''
		opts.separator 'OPTIONS:'

		opts.on('--module MODULENAME', 'module name of generated format') do |value|
			@module_name = value
		end

		opts.on('--class CLASSNAME', 'class name of generated format') do |value|
			@class_name = value
		end

		opts.on('--data DATAFILE', 'data filename (input)') do |value|
			@data_file = value
		end

		opts.on('--schema SCHEMAFILE', 'schema filename (input)') do |value|
			@schema_file = value
		end

		opts.on('--format FORMATFILE', 'format filename (output)') do |value|
			@format_file = value
		end

		parse_def_options opts

		# Verify arguments
		abort_err('An input file is required.', opts) if @data_file.nil? && @schema_file.nil?
	end

end
end
