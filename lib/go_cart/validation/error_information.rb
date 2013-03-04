class ErrorInformation
  attr_reader :failed_lines, :first_line, :validator

  def initialize(validator)
    @failed_lines = 0
    @first_line = 0
    @has_errors = false
    @validator = validator
  end

  def failed_values
    @failed_values ||= {}
  end

  def has_errors?
    @has_errors
  end

  def failed(input)
    @first_line = input.line_number unless has_errors?
    @has_errors = true
    @failed_lines += 1
    record_failed_value(input.value)
  end


  def inspect
    report || 'No errors'
  end

  def report(total_lines = nil)
    return nil unless has_errors?
    violating_lines_percent = total_lines ? "#{ ((failed_lines.to_f / total_lines.to_f) * 100.0).round(1)}%" : '--'

    <<-END
Validating #{validator.name} on field #{validator.field}
#{failed_lines} line(s) violated this rule (#{violating_lines_percent})
First line violating rule: #{first_line}
#{'Most Frequent Invalid Entries'.center(80, '.')}
#{most_frequent_failed_values(10).map {|v| "#{v[0]}:\t#{v[1]} times"}.join("\n")}
    END
  end

  private

  def record_failed_value(value)
    key = value.to_s.blank? ? '<missing>' : value.to_s

    unless failed_values.has_key?(key)
      return if failed_values.count > 1000
      failed_values[key] = 0
    end

    failed_values[key] += 1
  end

  def most_frequent_failed_values(limit)
    failed_values_copy = failed_values.dup
    if failed_values.count > limit
      threshold = failed_values.values.sort.reverse.instance_eval {|array| array[limit -1]}
      failed_values_copy.delete_if {|k,v| v < threshold}
    end

    failed_values_copy.map{|k,v| [k,v]}.sort{|v1,v2| v2[1] <=> v1[1]}
  end
end