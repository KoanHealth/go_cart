module GoCart
  class HashMapperConfig
    def initialize(mapper, conditions = [])
      @mapper = mapper
      @conditions = conditions
    end

    # Represents transforming a symbol from the input to the output.  If only one symbol is specified the
    # name of the symbol from the CSV record is assumed to be the same
    def map(destination_symbol, source_symbol = nil, &map_block)
      source_symbol = destination_symbol if source_symbol.nil?
      raise "Input row does not contain symbol #{source_symbol}" unless raw_transform_map[source_symbol]

      source = raw_transform_map[source_symbol]
      if map_block
        transform_map[destination_symbol] = guarded(->(row) { map_block.call(source.call(row)) })
      else
        transform_map[destination_symbol] = guarded(source)
      end
    end

    def map_object(destination_symbol, options = {}, &map_block)
      raise "map_object requires a block" unless map_block
      child_map = HashMapper.new(self, &map_block)
      unless options[:array]
        transform_map[destination_symbol] = guarded(child_map)
      else
        current_array = transform_map[destination_symbol]
        unless current_array.respond_to? :append_mapping
          transform_map[destination_symbol] = current_array = ArrayMap.new
        end
        current_array.append_mapping(child_map)
      end
    end

    def constant(destination_symbol, value = nil, &map_block)
      raise "constant requires a value or a block (but not both" unless value.nil? ^ map_block.nil?

      if (value)
        transform_map[destination_symbol] = ->(row) { value }
      else
        transform_map[destination_symbol] = ->(row) { map_block.call }
      end
    end

    # Equivalent of calling simple_map with all of the symbols for which you haven't already specified a mapping
    def simple_map_others
      raw_transform_map.keys.each { |s| transform_map[s] = raw_transform_map[s] unless transform_map[s] }
    end

    # Pass a list of symbols that should be directly mapped (key, type, and value)from the input to the root level of the output
    def simple_map(*fields)
      fields.each { |s| transform_map[s] = raw_transform_map[s] }
    end

    def if(condition, &condition_block)
      child_map = HashMapperConfig.new(self, conditions.push(condition))
      condition_block.call(child_map) if condition_block
      return child_map
    end

    def unless(condition, &condition_block)
      self.if(->(row) {!condition.call(row)}) &condition_block
    end

    private
    attr_reader :conditions

    def guarded(source)
      return source if conditions.empty?
      ->(row) { conditions.any? {|c| !c.call(row)} ? nil : source.call(row)}
    end

    def transform_map
      @mapper.send :transform_map
    end

    def raw_transform_map
      @mapper.send :raw_transform_map
    end
  end


end