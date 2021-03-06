require 'rubygems'
require 'yaml'
require_relative 'go_cart_def'

module GoCart
class GoCartRun < GoCartDef

	attr_accessor :data_file, :format_file, :mapper_name, :schema_name, :table_names, :db_suffix, :just_create
	attr_accessor :environment, :adapter, :database, :username, :password, :db_schema
	attr_accessor :bulk_load, :bulk_filename, :use_import

	def execute
		dbconfig = get_dbconfig
		FormatLoader.load_formats(@format_file)

		options = Hash.new
		options[:table_names] = @table_names unless @table_names.nil?
		options[:bulk_load] = @bulk_load unless @bulk_load.nil?
		options[:bulk_filename] = @bulk_filename unless @bulk_filename.nil?
		options[:use_import] = @use_import unless @use_import.nil?
		options[:db_suffix] = @db_suffix unless @db_suffix.nil?
		options[:db_schema] = @db_schema unless @db_schema.nil?

		runner = Runner.new()
		if @just_create
			schema = get_schema
			raise 'Must specify fully qualified schema or mapper class name' if schema.nil?
      runner.create_schema_tables(dbconfig, schema, options)
      unless @data_file.nil?
        runner.load_data_table(dbconfig, schema.tables.first[1], File.expand_path(@data_file), options)
      end
    else
      runner.load_data_files(dbconfig, Dir.glob(File.expand_path(@data_file)), get_mapper, options)
	  end
  end

	def parse_options(opts)
		opts.banner = "Usage: #{$0} run [OPTIONS] --format <FORMATFILE> --data <DATAFILE>"
		opts.separator ''
		opts.separator 'Maps and inserts data into a database using the specified format'
		opts.separator ''
		opts.separator 'OPTIONS:'

    # These are better defaults
    @use_import = false
    @bulk_load = true

		# Add arguments
		opts.on('--format FORMATFILE[,...]', 'format filenames') do |value|
			@format_file = split_args(value)
		end

		opts.on('--data DATAFILE', 'data filename to load') do |value|
			@data_file = value
		end

		opts.on('--mapper MAPPERCLASS', 'mapper classname (ie. MyModule::MyMapper)') do |value|
			@mapper_name = value
		end

		opts.on('--schema SCHEMACLASS', 'schema classname (ie. MyModule::MySchema)') do |value|
			@schema_name = value
		end

		opts.on('--tables TABLENAME[,...]', 'table names') do |value|
			@table_names = split_args(value)
		end

		opts.on('--env ENVIRONMENT', 'configuration environment') do |value|
			@environment = value
		end

		opts.on('--db DATABASE', 'database name') do |value|
  		@database = value
  	end

		opts.on('--adapter ADAPTER', 'database adapter') do |value|
  		@adapter = value
  	end

		opts.on('--username USERNAME', 'database username') do |value|
			@username = value
		end

		opts.on('--password PASSWORD', 'database password') do |value|
			@password = value
		end

		opts.on('--dbschema SCHEMAPATH', 'PostgreSQL schema search path') do |value|
			@db_schema = value
		end

		opts.on('--file FILENAME', 'bulk-load filename (output)') do |value|
			@bulk_filename = value
		end

		opts.on('--dbsuffix SUFFIX', 'suffix table name to make it unique') do |value|
			@db_suffix = value
		end

		opts.on('--load', 'perform bulk-load') do |value|
  		@bulk_load = true
  	end

		opts.on('--import', 'use ActiveRecord import') do |value|
  		@use_import = true
  	end

   	opts.on('--create', 'just create database tables (data file not required)') do |value|
  		@just_create = true
  	end

		parse_def_options opts

		# Verify arguments
		abort_err('An input file is required.', opts) if @data_file.nil? && !@just_create
		abort_err('A format file is required.', opts) if @format_file.nil?
		abort_err('Flag --load conflicts with --import.', opts) if @bulk_load && @use_import
	end

private

	def get_schema
		unless @schema_name.nil?
			schema = get_instance(@schema_name)
			raise "Invalid schema name: #{@schema_name}" if schema.nil?
			return schema
		end

		mapper = get_mapper
		return mapper.nil? ? nil : mapper.schema
	end

	def get_mapper
		unless @mapper_name.nil?
			mapper = get_instance(@mapper_name)
			raise "Invalid mapper name: #{@mapper_name}" if mapper.nil?
			return mapper
		end

		if @just_create && Mapper.get_all_mapper_classes.size == 1
			mapper_class = Mapper.get_last_mapper_class
			return mapper_class.new unless mapper_class.nil?
		end
		return nil
	end

  def get_dbconfig
		@environment = @environment || 'development'
		dbconfig = YAML::load(File.open(File.join(@script_dir,'../../config','database.yml')))[@environment]
		dbconfig['database'] = @database unless @database.nil?
    dbconfig['adapter']  = @adapter  unless @adapter.nil?
		dbconfig['username'] = @username unless @username.nil?
		dbconfig['password'] = @password unless @password.nil?
		return dbconfig
	end

end
end
