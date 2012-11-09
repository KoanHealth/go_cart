module GoCart

class Schema < CommonBase

	def create_table(symbol, options = {}, &code)
		table = SchemaTable.new(symbol, options)
		code.call(table) if block_given?
		add_table(table)
		return table
	end

	def add_index(table, columns, options = {})
		@tables[table].add_index(columns, options)
	end

end

class SchemaTable < CommonTable

	attr_accessor :id, :primary_key, :options, :temporary, :force, :indexes, :timestamps

	def initialize(symbol, options = {})
		super(symbol, options)
		@indexes = {}
	end

	def field(symbol, type, options = {})
		add_field(SchemaField.new(symbol, type, options))
	end

	def add_index(columns, options = {})
		@indexes[columns] = options
	end

	def get_options()
		options = Hash.new
		options[:id] = @id unless @id.nil?
		options[:primary_key] = @primary_key unless @primary_key.nil?
		options[:options] = @options unless @options.nil?
		options[:temporary] = @temporary unless @temporary.nil?
		options[:force] = @force unless @force.nil?
		return options
	end

	def get_parameters()
		s = "#{@symbol.inspect}"
		s += ", :id => #{@id}" unless @id.nil?
		s += ", :primary_key => #{@primary_key.inspect}" unless @primary_key.nil?
		s += ", :options => #{@options.inspect}" unless @options.nil?
		s += ", :temporary => #{@temporary}" unless @temporary.nil?
		s += ", :force => #{@force}" unless @force.nil?
		return s
	end

end

class SchemaField < CommonField

	attr_accessor :limit, :null, :default, :precision, :scale

	def format_value(value)
		return TypeUtils.format_value(@type, value)
	end

	def get_options()
		decimal_type_check
		options = Hash.new
		options[:null] = @null unless @null.nil?
		options[:default] = @default unless @default.nil?
		options[:precision] = @precision unless @precision.nil?
		options[:scale] = @scale unless @scale.nil?
		if [:text, :string, :binary].include?(@type) && !!@limit
			options[:limit] = @limit
		end
		return options
	end

	def get_parameters()
		decimal_type_check
		s = "#{@symbol.inspect}"
		s += ", :null => #{@null}" unless @null.nil?
		s += ", :default => #{@default.inspect}" unless @default.nil?
		s += ", :precision => #{@precision}" unless @precision.nil?
		s += ", :scale => #{@scale}" unless @scale.nil?
		if [:text, :string, :binary].include?(@type) && !!@limit
			s += ", :limit => #{@limit}"
		end
		return s
	end

private

	def decimal_type_check()
		# This is kind of a hack but MySql defaults to DECIMAL(10,0)
		if @type == :decimal && @scale.nil?
			@precision = 13
			@scale = 2
		end
	end

end

end
