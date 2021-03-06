module GoCart

class Schema < CommonBase

	def create_table(symbol, options = {}, &code)
		table = SchemaTable.new(symbol, options)
		code.call(table) if block_given?
		add_table(table)
		table
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
		options
	end

	def get_parameters()
		s = "#{@symbol.inspect}"
		s += ", :id => #{@id}" unless @id.nil?
		s += ", :primary_key => #{@primary_key.inspect}" unless @primary_key.nil?
		s += ", :options => #{@options.inspect}" unless @options.nil?
		s += ", :temporary => #{@temporary}" unless @temporary.nil?
		s += ", :force => #{@force}" unless @force.nil?
		s
	end

end

class SchemaField < CommonField

	attr_accessor :limit, :null, :default, :precision, :scale, :truncate

	def format_value(value)
    return nil if value.nil?
    if !@limit.nil? && @truncate && [:text, :string].include?(@type)
      value = value[0, @limit] if value.length > @limit
    end
    value
	end

	def get_options()
		decimal_type_check
		options = Hash.new
		options[:null] = @null unless @null.nil?
		options[:default] = @default unless @default.nil?
		options[:precision] = @precision unless @precision.nil?
		options[:scale] = @scale unless @scale.nil?
    options[:truncate] = @truncate unless @truncate.nil?
		if [:text, :string, :binary].include?(@type) && !@limit.nil?
			options[:limit] = @limit
    end
		options
	end

	def get_parameters()
		decimal_type_check
		s = "#{@symbol.inspect}"
		s += ", :null => #{@null}" unless @null.nil?
		s += ", :default => #{@default.inspect}" unless @default.nil?
		s += ", :precision => #{@precision}" unless @precision.nil?
    s += ", :scale => #{@scale}" unless @scale.nil?
    s += ", :truncate => #{@truncate}" unless @truncate.nil?
		if [:text, :string, :binary].include?(@type) && !@limit.nil?
			s += ", :limit => #{@limit}"
		end
		s
	end

  def to_sql(options = {})
    decimal_type_check
    s = @symbol.to_s + ' '  + get_sql_type
    s += ' NOT NULL' if !@null.nil? && !@null
    s += ' DEFAULT(' + format_sql_value(@default, value) + ')' unless @default.nil?
    s
  end

private

  def self.format_sql_value(type, value)
    case type
      when :string
        return "'#{value}'"
      when :integer
        return value
      when :date
        value = Date.parse(value)
        return "'#{value.year}-#{value.month}-#{value.day}'"
      when :boolean
        return value
      when :decimal
        return value
      when :float
        return value
      when :datetime
        value = DateTime.parse(value)
        return "'#{value.year}-#{value.month}-#{value.day} #{value.hour}:#{value.minute}:#{value.second}'"
      else
        raise "Invalid type: #{type}"
    end
  end

  def get_sql_type
    case @type
    when :string
      return "VARCHAR(#{@limit || 50})"
    when :text
      return 'TEXT'
    when :integer
      return 'INTEGER'
    when :float
      return 'DOUBLE PRECISION'
    when :decimal
      return "DECIMAL(#{@precision}, #{@scale})"
    when :datetime
      return 'TIMESTAMP'
    when :timestamp
      return 'TIMESTAMP'
    when :time
      return 'TIMESTAMP'
    when :date
      return 'DATE'
    when :binary
      return 'BYTEA'
    when :boolean
      return 'BOOLEAN'
    else
      return @type.to_s
    end
  end

	def decimal_type_check()
		# This is kind of a hack but MySql defaults to DECIMAL(10,0)
		if @type == :decimal && @scale.nil?
			@precision = 13
			@scale = 2
		end
	end

end

end
