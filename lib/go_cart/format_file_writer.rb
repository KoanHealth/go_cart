require 'erb'
require 'go_cart/file_utils'

module GoCart
class FormatFileWriter

	attr_accessor :template_directory, :module_name, :class_name

	def initialize(template_directory)
		@template_directory = template_directory
	end

	def write(formats, schemas, filename = nil, options = {})
		@module_name = options[:module_name] || "MyModule" if @module_name.nil?
		@class_name = options[:class_name] if @class_name.nil?

		if filename.nil?
			emit_output_file formats, schemas, $stdout, options
		else
			File.open(filename, 'w') do |file|
				emit_output_file formats, schemas, file, options
			end
		end
	end

private

	def emit_output_file(formats, schemas, output, options)
		emit_file_header output
		set_class_name = @class_name.nil?
		formats.each do |symbol, format|
			@class_name = TypeUtils.to_class_name(format.name) if set_class_name
			emit_format output, format, schemas[symbol]
			has_header = true
		end
		emit_file_footer output
	end

	def emit_file_header(output)
		emit(nil, nil, output, 'format_header.rb.erb')
	end

	def emit_format(output, format, schema)
		emit(format, schema, output, 'format.rb.erb')
	end

	def emit_file_footer(output)
		emit(nil, nil, output, 'format_footer.rb.erb')
	end

	def emit(format, schema, output, erb_file)
		template = IO.read(File.join(@template_directory, erb_file))
		output.puts ERB.new(template).result(binding)
	end

end
end
