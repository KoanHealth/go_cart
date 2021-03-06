require 'csv'

module GoCart
class FileUtils

	MAX_SAMPLES = 100
  CHAR_BUFFER_SIZE = 500
  MAX_LINE_LENGTH = 50000

  def self.clean_string(record)
    return record if record.nil? || record.blank?
    (record[0] == '"' ? record[1, record.length] : record).chomp('"').strip
  end

  def self.has_headers?(input_file)
		return get_csv_options(input_file, true)[:headers]
 	end

	def self.get_headers(input_file)
		headers = []
		options = get_csv_options(input_file)
		return headers unless options[:headers]

		CSV.foreach(input_file, options) do |row|
			if row.header_row?
				row.each do |symbol, value|
					headers << clean_string(value)
				end
			end
			break
		end
		return headers
	end

	def self.get_csv_options(input_file, ignore_noncsv = false)
		samples = 0
    header_line = nil
		has_header = false
		separators = Hash.new { |h,k| h[k] = 0 }

    eol_char = get_eol_char(input_file)
		File.open(input_file, 'r').each(eol_char) do |line|
      raise "Line is too long: #{line.length} chars (invalid line terminator?)" if line.length >= MAX_LINE_LENGTH
			next if line =~ /^\s*$/
			line.chomp!

      if samples <= 0
        header_line = line[0..100]
  			has_header = is_header_row?(line)
      end
			sum_separators(separators, line)

			samples += 1
			break if samples >= MAX_SAMPLES
		end
		separator_info = separators.max_by { |k,v| v }

		options = Hash.new
		if !separator_info.nil? && separator_info[1] >= samples
			options[:col_sep] = separator_info[0]
			# Files that are not comma separated tend not to use quotes
			options[:quote_char] = options[:col_sep] if options[:col_sep] != ','
			if has_header
				options[:headers] = true
				options[:return_headers] = true
				options[:header_converters] = :symbol
			else
				options[:headers] = false
      end
      options[:row_sep] = eol_char
		else
			raise "Data file is not a CSV file\nHEADER: #{header_line}..." unless ignore_noncsv
		end
		return options
	end

  def self.get_eol_char(input_file)
    eol_char = ''
    File.open(input_file, 'r+') do |io|
      until io.eof?
        io.read(CHAR_BUFFER_SIZE).each_char do |char|
          if char == "\n" || char == "\r"
            eol_char += char
          else
            return eol_char unless eol_char.empty?
          end
        end
      end
    end
    return "\n"
  end

=begin
	def self.fix_string(s)	# Fixes "invalid byte sequence in UTF-8" error
		s = s.encode('UTF-16', 'UTF-8', :invalid => :replace, :replace => '')
		s = s.encode('UTF-8', 'UTF-16')
		return s
	end
=end

private

	def self.is_header_row?(line)
		alpha = line.count('a-z') + line.count('A-Z')
		other = line.count('_#?&@*\\/ ')
		digit = line.count('0-9')

		total = alpha + other + digit
		return (100.0 * (alpha + other) / total) >= 90.0
	end

	def self.sum_separators(separators, line)
		# Remove a-zA-Z0-9_ and .+-'"\/() characters and count what is left
		line = line.gsub(/\w+/, '').gsub(/[.+\-'" ]/, '')
		line.each_char { |ch| separators[ch] += 1 }
	end

end
end
