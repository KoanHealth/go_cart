module GoCart
  module Errors
    class LoaderError < GoCartError

      attr_reader :filename, :line_number, :source

      def initialize(filename, line_number, source)
        @filename, @line_number, @source = filename, line_number, source
        info = {file: @filename, line: @line_number, error: @source.message}
        super format_message 'Loader failed', info
      end

    end
  end
end