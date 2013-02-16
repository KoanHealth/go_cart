module GoCart
  module Errors
    class MappingError < GoCartError

      attr_reader :field, :source

      def initialize(field, source)
        @field, @source = field, source
        info = {field: @field.symbol, error: @source.message}
        super format_message 'Mapping failed', info
      end

    end
  end
end