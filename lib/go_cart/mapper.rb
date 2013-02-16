module GoCart

class Mapper

	@@mappers = []

	attr_accessor :mappings, :format, :schema

	def initialize(format, schema)
		@mappings = {}
		@format = format
		@schema = schema
	end

	def create_mapping(symbol, options = {}, &code)
		mapping = Mapping.new(symbol, self, options)
		code.call(mapping) if block_given?
		add_mapping(mapping)
		return mapping
	end

	def add_mapping(mapping)
		raise "Duplicate mapping: #{mapping.symbol}" unless @mappings[mapping.symbol].nil?
		@mappings[mapping.symbol] = mapping
		return self
	end

	def get_mapping(symbol)
		return @mappings[symbol]
	end

	def get_schema_for_format(format_table)
		@mappings.each do |symbol, mapping|
			return mapping.schema_table if mapping.format_table.symbol == format_table.symbol
		end
		return nil
	end

	def to
		return :schema_table
	end

	def from
		return :format_table
	end

	def self.register(mapper_class)
		@@mappers << mapper_class unless mapper_class.nil?
	end

	def self.get_last_mapper_class
		return @@mappers.last
	end

	def self.get_all_mapper_classes
		return @@mappers
	end

end

class Mapping

	attr_accessor :symbol, :mapper, :maps, :schema_table, :format_table

	def initialize(symbol, mapper, options = {})
		@symbol = symbol
		@mapper = mapper
		@maps = {}

		options.each do |k, v|
			instance_variable_set("@#{k}", v) # if self.class.props.member?(k)
		end
		raise "Must specify to and from mapping tables" if @schema_table.nil? || @format_table.nil?
	end

	def map(symbol, value, options = {}, &code)
		raise "Invalid schema field: #{symbol}" if @schema_table.fields[symbol].nil?
		if value.class == Symbol
			raise "Invalid format field: #{value}" if @format_table.fields[value].nil?
			maps[symbol] = { :type => :symbol, :symbol => value, :options => options }
		elsif value.class == Proc
			maps[symbol] = { :type => :function, :function => value, :options => options }
		else
			maps[symbol] = { :type => :value, :value => value, :options => options }
		end
		maps[symbol][:translator] = code if block_given?
	end

	def map_fields(raw_values)
		field_data = []
		schema_table.fields.each do |symbol, schema_field|
      begin
        info = maps[schema_field.symbol]
        field_data << nil if info.nil?

        value = nil
        case info[:type]
        when :symbol
          format_field = format_table.fields[info[:symbol]]
          value = format_field.extract_value(raw_values[symbol])
        when :function
          value = info[:function].call(raw_values, symbol)
        else
          value = info[:value]
        end
        value = info[:translator].call(value) if info[:translator]
        field_data << value
      rescue Exception => e
        raise GoCart::Errors::MappingError.new(schema_field, e)
      end
		end
    field_data
	end

end

end
 