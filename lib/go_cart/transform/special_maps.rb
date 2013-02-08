module GoCart
  class ArrayMap
    def initialize(options)
      @options = options
    end

    def call(row)
      value = mappings.map { |m| m.call(row) }.compact
      value.length > 0 || @options[:include_empty] ? value : nil
    end

    def append_mapping(mapping)
      mappings << mapping
    end

    private
    def mappings
      @mappings ||= []
    end
  end

end