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

		# MMDDYYYY
		if value =~ /^([01]\d)([0123]\d)([129]\d{3})$/
			value = "#{$3}-#{$1}-#{$2}"
		# MM-DD-YYYY
    elsif value =~ /^([01]\d)\W([0123]\d)\W([129]\d{3})$/
  			value = "#{$3}-#{$1}-#{$2}"
		# M-D-YYYY
    elsif value =~ /^(\d{1,2})\W(\d{1,2})\W([129]\d{3})$/
  			value = "#{$3}-#{$1}-#{$2}"
		# YYYYMMDD
		elsif value =~ /^([129]\d{3})([01]\d)([0123]\d)$/
			value = "#{$1}-#{$2}-#{$3}"
		# YYYY-MM-DD
    elsif value =~ /^([129]\d{3})\W([01]\d)\W([0123]\d)$/
  			value = "#{$1}-#{$2}-#{$3}"
		# YYYY-M-D
    elsif value =~ /^([129]\d{3})\W(\d{1,2})\W(\d{1,2})$/
  			value = "#{$1}-#{$2}-#{$3}"
		end

		# OK, I give up
		return Date.parse value
	end

end
end
