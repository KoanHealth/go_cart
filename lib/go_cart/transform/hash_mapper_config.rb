module GoCart
  class HashMapperConfig
    def initialize(mapper, conditions = [])
      @mapper = mapper
      @conditions = conditions
    end

    # Represents transforming some source from the input to the output.
    #
    #If only the destination symbol is specified, then the input is the CSV value with the header of the same name.
    #If the second argument is specified as a string or symbol, then the input is the CSV value with the header of that name.
    #If the second argument is specified as a ->(row) lambda, the return of the lambda will be placed in the out put
    #
    # In all cases, the transform block will be called if supplied
    def map(destination_symbol, source = nil, &transform_block)

      source = destination_symbol if source.nil?
      source = source.to_sym if source.is_a? String
      if source.is_a? Symbol
        temp_source = raw_transform_map[source]
        raise "Input row does not contain symbol #{source}" unless temp_source
        source = temp_source
      end

      raise "Invalid source specified" unless source.is_a? Proc

      value = transform_block.nil? ?
          guarded(source) :
          guarded(->(row) { transform_block.call(source.call(row)) })

      if transform_map[destination_symbol].respond_to? :append_mapping
        transform_map[destination_symbol].append_mapping value
      else
        raise "#{destination_symbol} appears to have been mapped multiple times, but it is not an array" unless transform_map[destination_symbol].nil?
        transform_map[destination_symbol] = value
      end
    end

    def map_object(destination_symbol, &object_block)
      map(destination_symbol, object_block)
    end

    def array(destination_symbol, options = {}, &array_block)
      raise "#{destination_symbol} appears to have been mapped multiple times" unless transform_map[destination_symbol].nil?

      transform_map[destination_symbol] = array_map = ArrayMap.new(options)
      child_map = HashMapperConfig.new(self, conditions)

      class << child_map
        attr_accessor :destination_symbol
        alias :o_map :map
        alias :o_map_object :map_object

        def map(source = nil, &transform_block)
          o_map(destination_symbol, source) &transform_block
        end

        def map_object(&object_block)
          o_map(destination_symbol, object_block)
        end
      end
      child_map.destination_symbol = destination_symbol
      array_block.call(child_map) if array_block
      array_map
    end

    # Pass a list of symbols that should be directly mapped (key, type, and value)from the input to the root level of the output
    def simple_map(*fields)
      fields.flatten.map {|f| f.to_sym }.each { |s| transform_map[s] = raw_transform_map[s] }
    end

    def if(condition, &condition_block)
      child_map = HashMapperConfig.new(self, conditions.push(condition))
      condition_block.call(child_map) if condition_block
      return child_map
    end

    def unless(condition, &condition_block)
      self.if(->(row) { !condition.call(row) }, &condition_block)
    end

    private
    attr_reader :conditions

    def guarded(source)
      return source if conditions.empty?
      ->(row) { conditions.any? { |c| !c.call(row) } ? nil : source.call(row) }
    end

    def transform_map
      @mapper.send :transform_map
    end

    def raw_transform_map
      @mapper.send :raw_transform_map
    end
  end


end