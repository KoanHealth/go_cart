module GoCart
class GeneratorFromSchema < Generator

	def generate(schema_file, format_file = nil, options = {})
    fail "Schema file is required" if schema_file.blank?
		from_schema_file schema_file

		writer = FormatFileWriter.new @template_directory
		writer.write(@formats, @schemas, format_file, :module_name => @module_name, :class_name => @class_name)
	end

private

	def from_schema_file(schema_file)
		line_number = 0
		begin
			File.open(schema_file, 'r').each do |line|
				line_number += 1
				next if line =~ /^\s*$/
				line.chomp!

				if line =~ /^\s*##\s*(.+)/
					handle_directive $1
				elsif line =~ /\t/
					handle_field line.split("\t")
				else
					handle_field line.split(',')
				end
			end
		rescue
			raise $!, "#{$!} at line ##{line_number}", $!.backtrace
		end
	end

	def handle_directive(s)
		parts = s.split(':').map { |v| v.strip }
		case parts[0].downcase
		when 'module'
			define_module parts[1]
		when 'format'
			define_format parts[1]
		when 'table'
			define_table parts[1]
		when 'fields'
			define_fields parts[1]
		else
			raise "Unknown directive: #{parts[0]}"
		end
	end

	def handle_field(values)
		raise "Current table is undefined" if @current_format_table.nil?

		name = get_value('name', values)
		header = get_value('header', values)
		symbol = get_value('symbol', values)
		if name.nil? && header.nil? && symbol.nil?
			raise "A \"Name\", \"Header\", or \"Symbol\" field is required in schema: #{@current_format.name}"
		end

 		if symbol.nil?
			if header.nil?
				symbol = TypeUtils.to_symbol(name)
			else
				symbol = TypeUtils.to_symbol(header)
			end
		end

		index = get_value('index', values)
		pos_start = get_value('start', values)
		pos_end = get_value('end', values)
		length = get_value('length', values)
		type = get_value('type', values)
		description = get_value('description', values)

		limit = get_value('limit', values)
		if limit.nil? && !!type && type =~ /\w\s*\((\d+)\)/
			limit = $1
		end
		if limit.nil? && !length.nil?
			limit = length
		end
		null = get_value('null', values)
		default = get_value('default', values)
		precision = get_value('precision', values)
		scale = get_value('scale', values)

		options = Hash.new
		
		options[:header] = header unless header.nil?
		options[:index] = index.to_i unless index.nil?
		options[:start] = pos_start.to_i unless pos_start.nil?
		options[:end] = pos_end.to_i unless pos_end.nil?
		options[:length] = length.to_i unless length.nil?
		options[:name] = name unless name.nil?
		options[:description] = description unless description.nil?

		options[:limit] = limit.to_i unless limit.nil?
		options[:null] = null unless null.nil?
		options[:default] = default unless default.nil?
		options[:precision] = precision.to_i unless precision.nil?
		options[:scale] = scale.to_i unless scale.nil?

		true_type = TypeUtils.get_type_symbol(type || 'string')
		raise "Unrecognized type: #{type}" if true_type.nil?
		add_new_field(symbol, true_type, options)
	end

	def get_value(field, values)
		index = @current_fields[field]
		return nil if index.nil? || index >= values.size
		values[index]
	end

end
end
