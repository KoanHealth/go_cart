module GoCart
  class HashMapper
    def initialize(*args, &config_block)
      case args.count
        when 0 then @pending_configuration = ->(row) {initialize_with_csv_row(row, config_block)}
        when 1 then
          initialize_with_csv_row(args[0], config_block) if args[0].kind_of?(CSV::Row)
          @pending_configuration = ->(row) { initialize_with_hash(row, args[0], config_block)} if args[0].kind_of?(Hash)
          @pending_configuration = ->(row) { initialize_with_format_table(row, args[0], config_block)} if args[0].kind_of?(FormatTable)
        when 2 then
          initialize_with_hash(args[0], args[1], config_block)  if args[1].kind_of?(Hash)
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
      @map.each { |k, v| result[k] = v.call(row) }
      result
    end

    private
    def initialize_with_csv_row(row, config_block)
      @expected_field_count = row.count
      @map = {}
      row.headers.each do |h|
        index = row.index(h)
        @map[h] = ->(r){r[index]}
      end
      evaluate_config_block(config_block)
      @pending_configuration = nil
    end

    def initialize_with_hash(row, hash_configuration, config_block)
      @expected_field_count = hash_configuration.count
      @map = {}
      hash_configuration.each do |key,value|
        index = row.index(value)
        @map[key] = ->(r){r[index]}
      end
      evaluate_config_block(config_block)
      @pending_configuration = nil
    end

    def initialize_with_format_table(row, format_table, config_block)
      @expected_field_count = format_table.fields.count

      @map = {}
      format_table.fields.each do |key,value|
        index = row.index(value.header)
        type = value.type
        @map[key] = ->(r){ DataUtils.extract_value(type, r[index])} # TODO - We can probably use faster conversion routes
      end
      evaluate_config_block(config_block)
      @pending_configuration = nil
    end

    def evaluate_config_block(config_block)
      return unless config_block

      @raw_map = @map
      @map = {}

      config_block.call(self)
    end
  end
end
