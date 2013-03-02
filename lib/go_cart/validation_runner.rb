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


    def validate_data_files(data_files, mapper = nil, options = {})
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

        loader.load(file, format_table) do |raw, line_number|
          row = converter.convert(raw)
          table_reporter.validate(line_number, row)
        end

        p "Validation Report for #{file}"
        puts table_reporter.report

        file_count += 1
      end

      raise "File not found: #{data_files}" if file_count <= 0
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
        raise 'Must specify mapper class (ie. MyModule::MyMapper)' if mapper_class.nil?
        mapper = mapper_class.new
      end
      format_table = get_format_table(mapper, file)
      if format_table.nil?
        headers = FileUtils.get_headers(file)
        raise 'Unrecognized headers: ' + headers.join(',')
      end
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
      format_table
    end

  end

end
