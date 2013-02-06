module GoCart
  class HashMapper

    def initialize(*args, &config_block)
      case args.count
        when 0 then @pending_configuration = ->(row) {initialize_with_csv_row(row, config_block)}
        when 1 then
          initialize_with_csv_row(args[0], config_block) if args[0].kind_of?(CSV::Row)
          @pending_configuration = ->(row) { initialize_with_format_table(row, args[0], config_block)} if args[0].kind_of?(FormatTable)
        when 2 then
          initialize_with_format_table(args[0], args[1], config_block)  if args[1].kind_of?(FormatTable)
        else
          raise "Invalid number of arguments for hash mapper"
      end
    end

    def map(row)
      @pending_configuration.call(row) if @pending_configuration

      raise "Mapper has not been correctly initialized" unless defined? @expected_field_count

      unless row.count == @expected_field_count
        raise "Invalid Row.  #{row.count} columns encountered where #{@expected_field_count} expected"
      end

      result = {}
      transform_map.each { |k, v| result[k] = v.call(row) }
      result
    end

    class Config
      def initialize(transform_map, raw_transform_map)
        @transform_map = transform_map
        @raw_transform_map = raw_transform_map
      end
      attr_reader :transform_map, :raw_transform_map

      # Root of the mapping game.  Represents a symbol in the output hash.  By default, the source value
      # will be a symbol with the same name in the CSV definition
      def map(destination_symbol, source_symbol = nil, &map_block)
        source_symbol = destination_symbol if source_symbol.nil?
        raise "Input row does not contain symbol #{source_symbol}" unless raw_transform_map[source_symbol]

        source = raw_transform_map[source_symbol]
        if map_block
          transform_map[destination_symbol] = ->(row) {map_block.call(source.call(row))}
        else
          transform_map[destination_symbol] = source
        end
      end

      # Equivalent of calling simple_map with all of the symbols for which you haven't already specified a mapping
      def simple_map_others
        raw_transform_map.keys.each {|s| transform_map[s] = @raw_transform_map[s] unless transform_map[s]}
      end

      # Pass a list of symbols that should be directly mapped (key, type, and value)from the input to the root level of the output
      def simple_map(*fields)
        fields.each {|s| transform_map[s] = raw_transform_map[s]}
      end
    end

    private
    attr_reader :transform_map

    def initialize_with_csv_row(row, config_block)
      @expected_field_count = row.count
      @transform_map = {}
      row.headers.each do |h|
        index = row.index(h)
        transform_map[h] = ->(r){r[index]}
      end
      evaluate_config_block(config_block)
      @pending_configuration = nil
    end

    def initialize_with_format_table(row, format_table, config_block)
      @expected_field_count = format_table.fields.count

      @transform_map = {}
      format_table.fields.each do |key,value|
        index = row.index(value.header)
        type = value.type
        transform_map[key] = ->(r){ DataUtils.extract_value(type, r[index])} # TODO - We can probably use faster conversion routes
      end
      evaluate_config_block(config_block)
      @pending_configuration = nil
    end

    def evaluate_config_block(config_block)
      return unless config_block

      @raw_transform_map = transform_map
      @transform_map = {}

      config_block.call(Config.new(@transform_map, @raw_transform_map))
    end
  end
end
