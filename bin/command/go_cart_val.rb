require 'rubygems'
require 'yaml'
require_relative 'go_cart_def'

module GoCart
  class GoCartVal < GoCartDef
    def options
      @options ||= {}
    end

    def execute
      FormatLoader.load_formats(options[:format_file])

      runner = ValidationRunner.new()
      runner.validate_data_files(Dir.glob(File.expand_path(options[:data_file])), get_mapper, options)
    end

    def parse_options(opts)
      opts.banner = "Usage: #{$0} val [OPTIONS] --format <FORMATFILE> --data <DATAFILE>"
      opts.separator ''
      opts.separator 'Validates data in a file using the specified format'
      opts.separator ''
      opts.separator 'OPTIONS:'

      # Add arguments
      opts.on('--format FORMATFILE[,...]', 'format filenames') do |value|
        options[:format_file] = split_args(value)
      end

      opts.on('--data DATAFILE', 'data filename to load') do |value|
        options[:data_file] = value
      end

      opts.on('--mapper MAPPERCLASS', 'mapper classname (ie. MyModule::MyMapper)') do |value|
        options[:mapper_name] = value
      end

      opts.on('--schema SCHEMACLASS', 'schema classname (ie. MyModule::MySchema)') do |value|
        options[:schema_name] = value
      end

      parse_def_options opts

      # Verify arguments
      abort_err('An input file is required.', opts) if options[:data_file].nil?
      abort_err('A format file is required.', opts) if options[:format_file].nil?
    end

    private

    def get_schema
      unless options[:schema_name].nil?
        schema = get_instance(options[:schema_name])
        raise "Invalid schema name: #{options[:schema_name]}" if schema.nil?
        return schema
      end

      mapper = get_mapper
      mapper.nil? ? nil : mapper.schema
    end

    def get_mapper
      unless options[:mapper_name].nil?
        mapper = get_instance(options[:mapper_name])
        raise "Invalid mapper name: #{options[:mapper_name]}" if mapper.nil?
        return mapper
      end

      nil
    end

  end
end
