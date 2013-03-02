module GoCart
  module GroupValidator
    def validate_gathered
      result = self.class.group_validator_validate_group(gathered.keys)
      result.each do |valid_code|
        whitelist[valid_code] = gathered[valid_code].count
        gathered.delete(valid_code)
      end

      gathered.map do |key, value|
        value.map do |bad_input|
          failed(bad_input)
          blacklist[key] = value.count
        end
      end.reduce([]) { |a, v| a.concat v }

      gathered.clear
    end

    def validate(input)
      if whitelist.has_key? input.value
        return
      elsif blacklist.has_key? input.value
        failed(input)
        return
      end

      (gathered[input.value] ||= []).push input.dup
      validate_gathered if gathered.count >= self.class.group_validator_group_count
    end

    def finalize_validation
      validate_gathered unless gathered.empty?
    end

    def gathered
      @gathered ||= {}
    end

    def whitelist
      @whitelist ||= {}
    end

    def blacklist
      @blacklist ||= {}
    end
  end
end
