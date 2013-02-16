module GoCart
  module Errors
    class GoCartError < StandardError

      def format_message(message, options)
        formatted = message
        formatted_options = format_options(options)
        if formatted_options
          formatted << ' '
          formatted << formatted_options
        end
        formatted
      end

      def format_options(h)
        return nil if h.nil? || h.empty?
        h.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
      end

    end
  end
end