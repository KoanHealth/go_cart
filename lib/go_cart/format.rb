require 'go_cart/data_utils'

module GoCart

class Format < CommonBase

	def create_table(symbol, options = {}, &code)
		table = FormatTable.new(symbol, options)
		code.call(table) if block_given?
		add_table(table)
		return table
	end

end

class FormatTable < CommonTable

	attr_accessor :fixed_length, :headers, :name, :description, :filter

	def initialize(symbol, options = {})
		super(symbol, options)
		@fields_by_index = []
		@fields_by_header = {}
	end

	def add_field(field)
		super(field)
		if field.index.nil?
			@fields_by_index << field
			field.index = @fields_by_index.size
		else
			raise "Duplicate field index: #{field.symbol}" unless @fields_by_index[field.index-1].nil?
			@fields_by_index[field.index-1] = field
		end
		unless field.header.nil?
			raise "Duplicate field header: #{field.symbol}" unless @fields_by_header[field.header].nil?
			@fields_by_header[field.header.downcase] = field
			@headers = true
		end
		if @fixed_length.nil?
			@fixed_length = true if !!field.start
		end
		return self
	end

	def get_field_by_index(index)
		return @fields_by_index[index-1]
	end

	def get_field_by_header(header)
		return @fields_by_header[header.downcase]
	end

	def field(symbol, type, options = {})
		add_field(FormatField.new(symbol, type, options))
	end

	def get_headers()
		headers = []
		fields.each do |symbol, field|
			headers << field.header
		end
		return headers
	end

	def get_parameters()
		s = "#{@symbol.inspect}"
		s += ", :fixed_length => #{@fixed_length}" unless @fixed_length.nil?
		s += ", :headers => #{@headers}" unless @headers.nil?
		s += ", :name => #{@name.inspect}" unless @name.nil?
		s += ", :description => #{@description.inspect}" unless @description.nil?
		return s
	end

end

class FormatField < CommonField

  attr_accessor :index, :header, :name, :description
	attr_reader :start, :end, :length, :validation

  def initialize(symbol, type, options = {})
    super
    @length ||= (@end - @start) + 1 if @start && @end
  end

	def get_raw_value(line)
    line[@start-1, @length]
	end

	def extract_value(value)
    DataUtils.extract_value(@type, value)
	end

	def get_parameters()
		s = "#{@symbol.inspect}"
		s << ", :header => #{@header.inspect}" unless @header.nil?
		s << ", :index => #{@index}" unless @index.nil?
		s << ", :start => #{@start}" unless @start.nil?
		s << ", :end => #{@end}" unless @end.nil?
		s << ", :length => #{@length}" unless @length.nil?
		s << ", :name => #{@name.inspect}" unless @name.nil?
		s << ", :description => #{@description.inspect}" unless @description.nil?
    s
	end

end

end
