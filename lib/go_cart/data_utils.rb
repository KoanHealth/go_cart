module GoCart
class DataUtils

	def self.extract_value(type, value)
		return nil if value.nil?
		value = value.strip
		return nil if value.empty?

		case type
		when :string
			return value
		when :text
			return value
		when :integer
			return value.to_i
		when :float
			return Float(value)
		when :decimal
			return Float(value)
		when :datetime
			return value
		when :timestamp
			return value
		when :time
			return value
		when :date
			return extract_date(value)
		when :binary
			return value
		when :boolean
			return extract_boolean(value)
		else
			return value
		end
	end

	def self.extract_boolean(value)
    return true if value == '1'
    return false if value == '0'
		if ['y', 't'].include? value.downcase[0]
			return true
		elsif ['n', 'f'].include? value.downcase[0]
			return false
    else
      raise "Invalid boolean value: #{value}"
		end
	end

	def self.extract_date(value)
		# Null/Empty
		return nil if value == '00000000' || value =~ /^00\W00\W0000$/ || value =~ /^0000\W00\W00$/
		return nil if value == '99999999' || value =~ /^99\W99\W9999$/ || value =~ /^9999\W99\W99$/

		if value =~ /^(.+)\s+\d{1,2}:\d{2}:\d{2}/
			value = $1
		end

		patterns = [
			[ /^([01]\d)([0123]\d)([129]\d{3})$/, [2,0,1] ],        # MMDDYYYY
	    [ /^([01]\d)\W([0123]\d)\W([129]\d{3})$/, [2,0,1] ],    # MM-DD-YYYY
	    [ /^(\d{1,2})\W(\d{1,2})\W([12]\d{3})$/, [2,0,1] ],     # M-D-YYYY

			[ /^([129]\d{3})([01]\d)([0123]\d)$/, [0,1,2] ],        # YYYYMMDD
	    [ /^([129]\d{3})\W([01]\d)\W([0123]\d)$/, [0,1,2] ],    # YYYY-MM-DD
	    [ /^([12]\d{3})\W(\d{1,2})\W(\d{1,2})$/, [0,1,2] ],     # YYYY-M-D
		]
		patterns.each do |test|
			if value =~ test[0]
				order = test[1]
				parts = [ $1, $2, $3 ]
				y = parts[order[0]].to_i
				m = parts[order[1]].to_i
				d = parts[order[2]].to_i

				next if y < 1800 || y > 3000
				next if m < 1 || m > 12
				next if d < 1 || d > 31
				value = "#{y}-#{"%02d"%m}-#{"%02d"%d}"
				break
			end
		end

		# OK, I give up
		return Date.parse value
	end

end
end
