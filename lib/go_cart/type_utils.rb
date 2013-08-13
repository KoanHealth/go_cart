module GoCart
class TypeUtils

	# Supported types (from Rails/ActiveRecord)
	# :string, :text, :integer, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean

	def self.to_class_name(s)
		s = s.gsub(/[^a-zA-Z0-9_]/, '')
		s = '_' + s if s =~ /^\d+/
		s = s.gsub(/_{2,}/, '_')
		s = s.gsub(/_+$/, '')
		s[0] = s.capitalize[0]
		return s
	end

	def self.to_variable_name(s)
		s = s.gsub(/\s+/, '_')
		s = s.gsub(/[\/\-]/, '_')
		s = s.gsub(/[^a-zA-Z0-9_]/, '')
		s = '_' + s if s =~ /^\d+/
		s = s.gsub(/_{2,}/, '_')
		s = s.gsub(/_+$/, '')
		return underscore(s)
	end

	def self.to_symbol(s)
		return to_variable_name(s).to_sym
	end

	def self.can_upgrade_type(from_type, to_type)
		return true if from_type.nil?
		return true if to_type == :string
    return false if from_type == :string

		return true if from_type == :integer && to_type == :decimal
		return true if is_numeric_type(from_type) && to_type == :float
		return false if is_numeric_type(from_type) && to_type == :date

		return false if to_type == :boolean && from_type != :boolean
		return false if from_type == :decimal && to_type != :decimal
    return false if from_type == :float
		return true
	end

	def self.is_numeric_type(type)
		return [:integer, :float, :decimal].include? type
	end

	def self.infer_type_symbol(value)
		return nil if value.nil? || value.to_s == ''

		case value.downcase
		# MMDDYYYY
		when /^[01]\d[0123]\d[129]\d{3}$/
			return :date
		# MM-DD-YYYY
		when /^[01]\d\W[0123]\d\W[129]\d{3}$/
			return :date
		# M-D-YYYY
		when /^\d{1,2}\W\d{1,2}\W[129]\d{3}$/
			return :date
		# YYYYMMDD
		when /^[129]\d{3}[01]\d[0123]\d$/
			return :date
		# YYYY-MM-DD
		when /^[129]\d{3}\W[01]\d\W[0123]\d$/
			return :date
		# YYYY-M-D
		when /^[129]\d{3}\W\d{1,2}\W\d{1,2}$/
			return :date
		# Other stuff
    when 'y', 'n', 't', 'f', '1', '0', 'yes', 'no', 'true', 'false'
			return :boolean
		when /^[+-]?\d+\.\d{3,}$/
			return :float
		when /^[+-]?\d+\.\d{2}$/
			return :decimal
    when /^[+-]?\d{1,9}$/
      return :integer
		else
			return :string
		end
	end

	def self.get_type_symbol(type)
		return nil if type.nil?

		case type.downcase
		when /number\(\d+,\s*2\)/
			return :decimal
		when /number\(\d+,\s*\d+\)/
			return :float
		when /time/
			return :datetime
		when /date/
			return :date
		when /string/
			return :string
		when /varchar/
			return :string
		when /char/
			return :string
		when /text/
			return :string
		when /bool/
			return :boolean
		when /real/
			return :float
		when /float/
			return :float
		when /money/
			return :decimal
		when /currency/
			return :decimal
		when /decimal/
			return :decimal
		when /num/
			return :integer
		when /int/
			return :integer
		when /bit/
			return :boolean
		else
			return nil
		end
	end

	def self.underscore(s)
		return s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
		gsub(/([a-z\d])([A-Z])/,'\1_\2').
		tr("-", "_").
		downcase
	end

end
end
