#! /usr/bin/env ruby
require 'rubygems'
require 'optparse'
require_relative 'command/gocart_all'

module GoCart
class Main

	def run
		cmd = nil
		opts = OptionParser.new

		case ARGV[0]
		when /^g(en)?(erate)?$/i
			cmd = GoCart::GoCartGen.new
		when /^r(un)?$/i
			cmd = GoCart::GoCartRun.new
		when nil
			parse_err_options 'Command is required.', opts
		else
			parse_err_options "Invalid command: #{ARGV[0]}", opts
		end

		cmd.parse_options opts
		begin
			cmd.execute()
		rescue Exception => e
			GoCart::GoCartDef.new.abort_err e.message, e.backtrace.join("\n")
		end
	end

private

	def parse_err_options(message, opts)
		opts.banner = "Usage: #{$0} <COMMAND>"
		opts.separator ""
		opts.separator "Do some mapping chores"
		opts.separator ""
		opts.separator "COMMANDS:"
		opts.separator "\tGEN - Generate a format file from a data file or schema file"
		opts.separator "\tRUN - Insert data into a database using the specified format"

		GoCart::GoCartDef.new.abort_err message, opts
	end

end
end

GoCart::Main.new.run
