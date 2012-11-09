require 'tempfile'
require 'go_cart/dialect_mysql'
require 'go_cart/dialect_postgresql'

module GoCart
class Runner

	attr_accessor :format_file, :mapper_name, :table_name
	attr_accessor :bulk_load, :bulk_filename

	def initialize(format_file)
		@format_file = format_file
	end

  def load_data(dbconfig, data_file, options = {})
	  load_options options

	  # begin
		require @format_file
	  # end

		file_count = 0
		mapper = get_mapper

		Dir.glob(data_file).each do |file|
			if @table_name.nil? && FileUtils.has_headers?(file)
				headers = FileUtils.get_headers(file)
				format_table = mapper.format.identify_table(headers)
				raise "Unrecognized headers in file #{file}" if format_table.nil?
			elsif !@table_name.nil?
				format_table = mapper.format.get_table(@table_name.to_sym)
			elsif mapper.format.tables.size == 1
				format_table = mapper.format.tables.first[1]
			else
				raise "Must specify a table name"
			end
			schema_table = mapper.schema.tables[format_table.symbol]

			if format_table.fixed_length
				loader = LoaderFromFixed.new
			else
				loader = LoaderFromCsv.new
			end

			bulk_delete = false
      begin
        if @bulk_load || @bulk_filename
          if @bulk_filename.nil?
            @bulk_filename = Tempfile.new('gocart')
            bulk_delete = true
          end
          target = TargetFile.new get_dialect(dbconfig), @bulk_filename
        else
          target = TargetDb.new dbconfig
        end

        loader.load(file, mapper, format_table, schema_table, target)
        target.import(dbconfig, mapper, schema_table) if @bulk_load
      ensure
  			target.delete if bulk_delete
      end
			file_count += 1
		end

		raise "File not found: #{data_file}" if file_count <= 0
	end

  def create_tables_only(dbconfig, options = {})
	  load_options options

	  # begin
    require @format_file
	  # end

 		mapper = get_mapper

    tables = []
    if @table_name.nil?
      tables.concat mapper.format.tables.map { |symbol, table| table }
    else
      tables << mapper.format.get_table(@table_name.to_sym)
    end
    tables.each do |format_table|
        schema_table = mapper.schema.tables[format_table.symbol]

        target = TargetDb.new dbconfig
        target.open mapper, schema_table
        target.close
    end
  end

private

	def load_options(options)
		@mapper_name = options[:mapper_name]
		@table_name = options[:table_name]
		@bulk_load = options[:bulk_load]
		@bulk_filename = options[:bulk_filename]
	end

  def get_mapper
 		unless @mapper_name.nil?
 			parts = @mapper_name.split('::')
 			if parts.length == 1
 				return Kernel.const_get(parts[0]).new
 			else
 				return Kernel.const_get(parts[0]).const_get(parts[1]).new
 			end
 		end

 		mapper_class = Mapper.get_last_mapper_class
 		raise "Please specify mapper class (ie. MyModule::MyMapper)" if mapper_class.nil?
 		return mapper_class.new
 	end

  def get_dialect(dbconfig)
    adapter = dbconfig['adapter']
    if adapter =~ /mysql/i
      return DialectMySql.new
    elsif adapter =~ /postgresql/i
      return DialectPostgresql.new
    else
      raise "Adapter '#{adapter}' is not currently supported"
    end
  end

end
end
