require 'rubygems'
require 'yaml'
require_relative 'gocart_def'

module GoCart
class GoCartRun < GoCartDef

	attr_accessor :data_file, :format_file, :mapper_name, :table_name, :suffix, :just_create
	attr_accessor :environment, :adapter, :database, :username, :password
	attr_accessor :bulk_load, :bulk_filename, :use_import

	def execute()
		dbconfig = get_dbconfig
		runner = Runner.new(@format_file)

		options = Hash.new
		options[:mapper_name] = @mapper_name unless @mapper_name.nil?
		options[:table_name] = @table_name unless @table_name.nil?
		options[:bulk_load] = @bulk_load unless @bulk_load.nil?
		options[:bulk_filename] = @bulk_filename unless @bulk_filename.nil?
		options[:use_import] = @use_import unless @use_import.nil?
		options[:suffix] = @suffix unless @suffix.nil?

		if @just_create
      runner.create_tables_only(dbconfig, options)
    else
      runner.load_data(dbconfig, @data_file, options)
	  end
  end

	def parse_options(opts)
		opts.banner = "Usage: #{$0} run [OPTIONS] --format <FORMATFILE> --data <DATAFILE>"
		opts.separator ''
		opts.separator 'Maps and inserts data into a database using the specified format'
		opts.separator ''
		opts.separator 'OPTIONS:'

		# Add arguments
		opts.on('--format FORMATFILE', 'format filename') do |value|
			@format_file = value
		end

		opts.on('--data DATAFILE', 'data filename to load') do |value|
			@data_file = value
		end

		opts.on('--mapper MAPPERCLASS', 'mapper classname') do |value|
			@mapper_name = value
		end

		opts.on('--table TABLENAME', 'table name') do |value|
			@table_name = value
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

		opts.on('--file FILENAME', 'bulk-load filename (output)') do |value|
			@bulk_filename = value
		end

		opts.on('--suffix SUFFIX', 'suffix table name to make it unique') do |value|
			@suffix = value
		end

		opts.on('--load', 'perform bulk-load') do |value|
  		@bulk_load = true
  	end

		opts.on('--import', 'use ActiveRecord import') do |value|
  		@use_import = true
  	end

   	opts.on('--create', 'just create database tables') do |value|
  		@just_create = true
  	end

		parse_def_options opts

		# Verify arguments
		abort_err('An input file is required.', opts) if @data_file.nil? && !@just_create
		abort_err('A format file is required.', opts) if @format_file.nil?
		abort_err('Flag --load conflicts with --import.', opts) if @bulk_load && @use_import
	end

private

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
