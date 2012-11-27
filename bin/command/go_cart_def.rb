require 'rubygems'
require 'optparse'
require 'colorize'

module GoCart
class GoCartDef

	attr_accessor :verbose, :no_color, :left_overs

	def initialize()
		@left_overs = []
		@script_dir = File.expand_path(File.dirname(__FILE__))
	end

	def parse_def_options(opts)
		opts.on("-v", "--verbose", "show verbose output") do
			@verbose = true
		end

		opts.on("-c", "--nocolor", "do not colorize messages") do
			@no_color = true
		end

		opts.on("-h", "--help", "show this message") do
			puts opts
			exit false
		end

		opts.parse!.each do |left_over|
			@left_overs << left_over
		end
	end

	def abort_err(message, opts = nil)
		warn opts unless opts.nil?
		unless @no_color
			abort 'ERROR:'.white.on_red + (' ' + message).swap
		else
			abort 'ERROR: ' + message
		end
	end

end
end
