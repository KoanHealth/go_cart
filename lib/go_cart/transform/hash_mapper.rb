module GoCart
  class HashMapper
    class FastRow
      def self.fast(row, mapper)
        return row if row.is_a? FastRow
        FastRow.new(row, mapper.send(:raw_transform_map))
      end

      def self.raw(row)
        row.is_a?(FastRow) ? row.raw_row : row
      end

      def count
        raw_row.count
      end

      def [](header_or_index)
        header_or_index.is_a?(Integer) ? raw_row[header_or_index] : @raw_map[header_or_index].call(raw_row)
      end

      private
      attr_reader :raw_row

      def initialize(raw_row, raw_map)
        @raw_row = raw_row
        @raw_map = raw_map
      end
    end

    def initialize(*args, &config_block)
      case args.count
        when 0 then
          @pending_configuration = ->(row) { initialize_with_csv_row(row, config_block) }
        when 1 then
          initialize_as_child(args[0], config_block) if args[0].kind_of?(HashMapperConfig)
          initialize_with_csv_row(args[0], config_block) if args[0].kind_of?(CSV::Row)
          @pending_configuration = ->(row) { initialize_with_format_table(row, args[0], config_block) } if args[0].kind_of?(FormatTable)
        when 2 then
          initialize_with_format_table(args[0], args[1], config_block) if args[1].kind_of?(FormatTable)
        else
          raise "Invalid number of arguments for hash mapper"
      end
    end

    def map(row, options = {})
      @pending_configuration.call(FastRow.raw(row)) if @pending_configuration

      raise "Mapper has not been correctly initialized" unless defined? initialized?

      unless row.count == expected_field_count
        raise "Invalid Row.  #{row.count} columns encountered where #{expected_field_count} expected"
      end

      result = {}
      fast_row = FastRow.fast(row, self)
      transform_map.each do |k, v|
        value = v.call(fast_row)
        result[k] = value if value
      end
      result.length > 0 || options[:return_empty_objects] ? result : nil
    end

    alias :call :map

    private
    attr_reader :transform_map, :raw_transform_map

    def initialized?
      !raw_transform_map.nil?
    end

    def expected_field_count
      raw_transform_map.count
    end

    def initialize_with_csv_row(row, config_block)
      @raw_transform_map = @transform_map = {}
      row.headers.each do |h|
        index = row.index(h)
        transform_map[h] = ->(r) { r[index] }
      end
      evaluate_config_block(config_block)
      @pending_configuration = nil
    end

    def initialize_with_format_table(row, format_table, config_block)
      @raw_transform_map = @transform_map = {}
      format_table.fields.each do |key, value|
        index = row.index(value.header)
        type = value.type
        #TODO - are there faster conversion routes, particularly for boolean values?
        transform_map[key] = ->(r) { DataUtils.extract_value(type, r[index]) }
      end
      evaluate_config_block(config_block)
      @pending_configuration = nil
    end

    def initialize_as_child(parent_mapper, config_block)
      @transform_map = {}
      @raw_transform_map = parent_mapper.send :raw_transform_map
      @pending_configuration = nil
      config_block.call(HashMapperConfig.new(self))
    end

    def evaluate_config_block(config_block)
      return unless config_block

      @transform_map = {}
      config_block.call(HashMapperConfig.new(self))
    end
  end

end