module GoCart

class CommonBase

	attr_accessor :name, :tables

	def initialize(name = nil)
		@name = name unless name.nil?
		@tables = {}
	end

	def add_table(table)
		raise "Duplicate table: #{table.symbol}" unless @tables[table.symbol].nil?
		@tables[table.symbol] = table
		create_attr table.symbol.to_s, table
		return self
	end

	def get_table(symbol)
		return @tables[symbol]
	end

	def identify_table(headers)
		@tables.each do |symbol, table|
			return table if table.matches?(headers)
		end
		return nil
	end

protected

	def create_method(name, &block)
		self.class.send(:define_method, name, &block)
	end

	def create_attr(name, value)
		create_method("#{name}=".to_sym) { |val| 
			instance_variable_set("@" + name, val)
		}
		create_method(name.to_sym) { 
			instance_variable_get("@" + name) 
		}
		instance_variable_set("@" + name, value)
	end

end

class CommonTable

	attr_accessor :symbol, :fields

	def initialize(symbol, options = {})
		@symbol = symbol
		@fields = {}
		options.each do |k, v|
			instance_variable_set("@#{k}", v)
		end
	end

	def add_field(field)
		raise "Duplicate field: #{field.symbol}" unless @fields[field.symbol].nil?
		@fields[field.symbol] = field
		return self
	end

	def get_field(symbol)
		return @fields[symbol]
	end

	def get_columns()
		columns = []
		fields.each do |symbol, field|
			columns << symbol
		end
		return columns
	end

	def matches?(headers)
		if headers.size == @fields.size
			@fields.each do |symbol, field|
				found_it = false
				headers.each do |header|
					if header.casecmp(field.header || field.name) == 0
						found_it = true
						break
					end
				end
				return false unless found_it
				# Case-sensitive:
				#return false unless headers.include? field.header
			end
			return true
		end
		return false
	end

	def string(symbol, options = {})
		field(symbol, :string, options)
	end

	def text(symbol, options = {})
		field(symbol, :text, options)
	end

	def integer(symbol, options = {})
		field(symbol, :integer, options)
	end

	def float(symbol, options = {})
		field(symbol, :float, options)
	end

	def decimal(symbol, options = {})
		field(symbol, :decimal, options)
	end

	def datetime(symbol, options = {})
		field(symbol, :datetime, options)
	end

	def timestamp(symbol, options = {})
		field(symbol, :timestamp, options)
	end

	def date(symbol, options = {})
		field(symbol, :date, options)
	end

	def time(symbol, options = {})
		field(symbol, :time, options)
	end

	def binary(symbol, options = {})
		field(symbol, :binary, options)
	end

	def boolean(symbol, options = {})
		field(symbol, :boolean, options)
	end

end

class CommonField

	attr_accessor :symbol, :type

	def initialize(symbol, type, options = {})
		@symbol = symbol
		@type = type
		options.each do |k, v|
			instance_variable_set("@#{k}", v)
		end
	end

end

end
