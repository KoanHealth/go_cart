module GoCart
  module GroupValidator
    def validate_gathered
      result = self.class.group_validator_validate_group(gathered.keys)
      result.each do |valid_code|
        whitelist[valid_code] = gathered[valid_code].count
        gathered.delete(valid_code)
      end

      gathered.map do |key, value|
        value.map { |bad_input| failed(bad_input, "Invalid code #{key} encountered in field #{bad_input.field}") }
      end.reduce([]) { |a, v| a.concat v }

      gathered.clear
    end

    def validate(input)
      return nil if whitelist.has_key? input.value

      (gathered[input.value] ||= []).push input.dup
      validate_gathered if gathered.count >= self.class.group_validator_group_count
    end

    def get_errors
      validate_gathered unless gathered.empty?
      errors
    end

    def gathered
      @gathered ||= {}
    end

    def whitelist
      @whitelist ||= {}
    end
  end
end
