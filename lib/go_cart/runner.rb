require 'tempfile'
require 'go_cart/dialect_mysql'
require 'go_cart/dialect_postgresql'

module GoCart
class Runner

	attr_accessor :format_file, :mapper_name, :table_names, :suffix, :schema
	attr_accessor :bulk_load, :bulk_filename, :use_import

	def initialize(format_file)
		@format_file = format_file
	end

	def load_data(dbconfig, data_files, options = {})
	  load_options options

	  # begin
	  Dir.glob(@format_file) { |file| require file }
	  # end

		file_count = 0
		mapper = get_mapper

		data_files.each do |file|
			format_table = get_format_table(mapper, file)
			schema_table = mapper.get_schema_for_format(format_table)
			raise "Cannot find schema mapping for #{format_table.symbol}" if schema_table.nil?

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
          target = TargetFile.new self.class.get_dialect(dbconfig), @bulk_filename
        else
          target = TargetDb.new dbconfig
        end
        target.suffix = @suffix
        target.schema = @schema

        loader.load(file, mapper, format_table, schema_table, target)
        target.import(dbconfig, mapper, schema_table) if @bulk_load
      ensure
  			target.delete if bulk_delete unless target.nil?
      end
			file_count += 1
		end

		raise "File not found: #{data_files}" if file_count <= 0
	end

	def self.save_data(dbconfig, schema_table, filename, options = {})
		target = Target.new()
	  target.suffix = options[:suffix]
	  target.schema = options[:schema]
	  target.save_table(dbconfig, get_dialect(dbconfig), schema_table, filename)
	end

	def self.drop_schema(dbconfig, schema)
		target = Target.new()
	  target.drop_schema(dbconfig, get_dialect(dbconfig), schema)
	end

  def create_tables_only(dbconfig, options = {})
	  load_options options

	  # begin
	  Dir.glob(@format_file) { |file| require file }
	  # end

 		mapper = get_mapper

    tables = []
    if @table_names.nil?
      tables.concat mapper.format.tables.map { |symbol, table| table }
    else
	    @table_names.each do |table_name|
		    format_table = mapper.format.get_table(table_name.to_sym)
		    raise "Unrecognized table #{table_name}" if format_table.nil?
		    tables << format_table
	    end
    end
    tables.each do |format_table|
      schema_table = mapper.get_schema_for_format(format_table)

      target = TargetDb.new dbconfig
      target.suffix = @suffix
      target.schema = @schema
      target.open mapper, schema_table
      target.close
    end
  end

private

	def get_format_table(mapper, file)
		format_table = nil
		has_headers = GoCart::FileUtils.has_headers?(file)
		if @table_names.nil? && has_headers
			headers = GoCart::FileUtils.get_headers(file)
			format_table = mapper.format.identify_table(headers)
			raise "Unrecognized headers in file #{file}" if format_table.nil?
		elsif !@table_names.nil? && has_headers
			headers = GoCart::FileUtils.get_headers(file)
			@table_names.each do |table_name|
				format_table = mapper.format.get_table(table_name.to_sym)
				raise "Unrecognized table #{table_name}" if format_table.nil?
				break if format_table.matches?(headers)
				format_table = nil
			end
			raise "Unrecognized headers in file #{file}" if format_table.nil?
		elsif mapper.format.tables.size == 1
			format_table = mapper.format.tables.first[1]
		else
			raise "Must specify a table name"
		end
		return format_table
	end

	def load_options(options)
		@mapper_name = options[:mapper_name]
		@table_names = options[:table_names]
		@suffix = options[:suffix]
		@schema = options[:schema]

		@bulk_load = options[:bulk_load]
		@bulk_filename = options[:bulk_filename]
		@use_import = options[:use_import]
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
 		raise "Must specify mapper class (ie. MyModule::MyMapper)" if mapper_class.nil?
 		return mapper_class.new
 	end

  def self.get_dialect(dbconfig)
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
