module GoCart
  class ArrayMap
    def call(row)
      mappings.map { |m| m.call(row) }.compact
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