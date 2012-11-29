require 'tempfile'
require 'go_cart/dialect_mysql'
require 'go_cart/dialect_postgresql'

module GoCart
class Runner

	attr_accessor :table_names, :db_suffix, :db_schema
	attr_accessor :bulk_load, :bulk_filename, :use_import

	def self.load_formats(formats)
		formats.each do |format|
			file_count = 0
			Dir.glob(format) do |format_file|
				require format_file
				file_count += 1
			end
			raise "Format files not found: #{format}" unless file_count > 0
		end
	end

	def create_schema_tables(dbconfig, schema = nil, options = {})
    load_options options

    tables = []
    if @table_names.nil?
      tables.concat schema.tables.map { |symbol, table| table }
    else
      @table_names.each do |table_name|
	      schema_table = schema.get_table(table_name.to_sym)
	      raise "Unrecognized table #{table_name}" if schema_table.nil?
	      tables << schema_table
      end
    end

    tables.each do |schema_table|
      target = TargetDb.new dbconfig
      target.db_suffix = @db_suffix
      target.db_schema = @db_schema
      target.open schema_table
      target.close
    end
  end

	def load_data_table(dbconfig, schema_table, filename, options = {})
		load_options options

	  target = TargetFile.new self.class.get_dialect(dbconfig, filename), filename
		target.db_suffix = @db_suffix
		target.db_schema = @db_schema

		target.import(dbconfig, schema_table)
	end

	def load_data_files(dbconfig, data_files, mapper = nil, options = {})
	  load_options options

		file_count = 0
		data_files.each do |file|
			file_mapper, format_table = get_mapper_format(file, mapper)
			schema_table = file_mapper.get_schema_for_format(format_table)
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
        target.db_suffix = @db_suffix
        target.db_schema = @db_schema

        loader.load(file, file_mapper, format_table, schema_table, target)
        target.import(dbconfig, schema_table) if @bulk_load
      ensure
  			target.delete if bulk_delete unless target.nil?
      end
			file_count += 1
		end

		raise "File not found: #{data_files}" if file_count <= 0
	end

	def self.save_data_file(dbconfig, schema_table, filename, options = {})
		target = Target.new()
	  target.db_suffix = options[:db_suffix]
	  target.db_schema = options[:db_schema]
	  target.save_table(dbconfig, get_dialect(dbconfig), schema_table, filename)
	end

	def self.drop_db_schema(dbconfig, schema_name)
		target = Target.new()
	  target.drop_db_schema(dbconfig, get_dialect(dbconfig), schema_name)
	end

private

	def get_mapper_format(file, mapper = nil)
		if mapper.nil?
			Mapper.get_all_mapper_classes.each do |mapper_class|
				mapper = mapper_class.new
				format_table = get_format_table(mapper, file)
				return mapper, format_table unless format_table.nil?
			end

			mapper_class = Mapper.get_last_mapper_class
			raise "Must specify mapper class (ie. MyModule::MyMapper)" if mapper_class.nil?
			mapper = mapper_class.new
		end
		format_table = get_format_table(mapper, file)
		raise "Unrecognized headers in file #{file}" if format_table.nil?
		return mapper, format_table
	end

	def get_format_table(mapper, file)
		format_table = nil
		has_headers = GoCart::FileUtils.has_headers?(file)
		if @table_names.nil? && has_headers
			headers = GoCart::FileUtils.get_headers(file)
			format_table = mapper.format.identify_table(headers)
		elsif !@table_names.nil? && has_headers
			headers = GoCart::FileUtils.get_headers(file)
			@table_names.each do |table_name|
				format_table = mapper.format.get_table(table_name.to_sym)
				next if format_table.nil?
				break if format_table.matches?(headers)
				format_table = nil
			end
		elsif mapper.format.tables.size == 1
			format_table = mapper.format.tables.first[1]
		end
		return format_table
	end

	def load_options(options)
		@table_names = options[:table_names]
		@db_suffix = options[:db_suffix]
		@db_schema = options[:db_schema]

		@bulk_load = options[:bulk_load]
		@bulk_filename = options[:bulk_filename]
		@use_import = options[:use_import]
	end

  def self.get_dialect(dbconfig, filename = nil)
	  field_separator = "\t"
	  unless filename.nil?
		  options = FileUtils.get_csv_options(filename)
		  field_separator = options[:col_sep]
	  end

    adapter = dbconfig['adapter']
    if adapter =~ /mysql/i
      return DialectMySql.new(field_separator)
    elsif adapter =~ /postgresql/i
      return DialectPostgresql.new(field_separator)
    else
      raise "Adapter '#{adapter}' is not currently supported"
    end
  end

end
end
