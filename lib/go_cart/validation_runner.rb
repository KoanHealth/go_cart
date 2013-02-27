module GoCart
  class ValidationRunner
    def self.load_formats(formats)
      formats.each do |format|
        file_count = 0
        Dir.glob(File.expand_path(format)) do |format_file|
          require format_file
          file_count += 1
        end
        raise "Format files not found: #{format}" unless file_count > 0
      end
    end

  end

  def validate_data_files(data_files, mapper = nil, options = {})
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

      converter = RawTableConverter.new(format_table)
      table_reporter = ValidationRecorder.new(format_table)

      loader.open(file, format_table) do |raw, line_number|
        row = converter.convert(raw)
        table_reporter.validate(line_number, row)
      end

      p "Validation Report for #{file}"
      p table_reporter.report

      file_count += 1
    end

    raise "File not found: #{data_files}" if file_count <= 0
  end

end
