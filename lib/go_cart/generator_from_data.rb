require 'rubygems'
require 'csv'
require_relative 'type_utils'
require_relative 'file_utils'
require_relative 'format_file_writer'

module GoCart
class GeneratorFromData < Generator

	MAX_SAMPLES = 2500

	def generate(data_file, format_file = nil, options = {})
		Dir.glob(data_file).each do |file|
			from_data_file file
		end

		writer = FormatFileWriter.new @template_directory
		writer.write(@formats, @schemas, format_file, :module_name => @module_name, :class_name => @class_name)
	end

private

	def from_data_file(data_file)
		define_format File.basename(data_file, '.*')
		define_table @current_format.name

		samples = 0
		symbol_map = {}
		options = FileUtils.get_csv_options(data_file)
		CSV.foreach(data_file, options) do |row|
			if options[:headers]
				if row.header_row?
					@current_fields.clear
					row.each do |header|
						symbol = TypeUtils.to_symbol(header[1])
						add_new_field(symbol, :string, { :header => header[1] })
						@current_fields[header[0]] = Hash.new { |h,k| h[k] = { :count => 0, :size => 0 } }
						symbol_map[header[0]] = symbol
					end
				else
					@current_fields.each do |symbol, types|
						value = row[symbol]
						type = TypeUtils.infer_type_symbol(value)
						next if type.nil?

						hash = types[type]
						hash[:count] += 1
						hash[:size] = value.length unless hash[:size] > value.length
					end
				end
			else
				if @current_fields.empty?
					row.each_with_index do |value, index|
						symbol = "field#{index+1}".to_sym
						add_new_field(symbol, :string, { :index => index+1 })
						@current_fields[symbol] = Hash.new { |h,k| h[k] = { :count => 0, :size => 0 } }
						symbol_map[symbol] = symbol
					end
				end
				row.each_with_index do |value, index|
					symbol = "field#{index+1}".to_sym
					types = @current_fields[symbol]
					type = TypeUtils.infer_type_symbol(value)
					next if type.nil?

					hash = types[type]
					hash[:count] += 1
					hash[:size] = value.length unless hash[:size] > value.length
				end
			end
			break if samples >= MAX_SAMPLES
			samples += 1
		end
		@current_fields.each do |symbol, types|
			symbol = symbol_map[symbol]
			format_field = @current_format_table.get_field(symbol)
			schema_field = @current_schema_table.get_field(symbol)

			type, limit = get_best_type_and_size(types)

			format_field.type = schema_field.type = type
			schema_field.limit = limit
		end
		@current_fields.clear
	end

	def get_best_type_and_size(types)
		best_type = nil
		best_size = best_count = 0

		types.each do |type, info|
			cur_size = info[:size]
			cur_count = info[:count]

			best_size = cur_size if cur_size > best_size
			if TypeUtils.can_upgrade_type(best_type, type)
				best_type = type
				best_count = cur_count
			end
		end
		return :string, 50 if best_type.nil?

		# Round up to the first larger number that is divisible by 10
		best_size = ((best_size + 1.0) / 10.0).ceil * 10
		return best_type, best_size
	end

end
end
