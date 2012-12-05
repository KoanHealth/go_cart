require_relative 'go_cart_def'

module GoCart
class GoCartSql < GoCartDef

	attr_accessor :from_format, :from_schema, :from_table, :to_format, :to_schema, :to_table

	def execute()
		Runner.load_formats(@from_format) unless @from_format.nil?
		Runner.load_formats(@to_format) unless @to_format.nil?

		from_table = get_table(@from_schema, @from_table)
		to_table = get_table(@to_schema, @to_table)

		# mapping variable is used by ERB template
		mapping = map_fields(from_table, to_table)
		template_directory = File.join(@script_dir, '../../templates')
		template = IO.read(File.join(template_directory, 'insert_select.sql.erb'))
		puts ERB.new(template).result(binding)
	end

	def get_table(schema_class, table_name)
		if schema_class.nil?
			Mapper::get_all_mapper_classes.each do |mapper_class|
				mapper = mapper_class.new
				table = mapper.schema.get_table(table_name.to_sym)
				return table unless table.nil?
			end
		else
			schema = get_instance(schema_class)
			return schema.get_table(table_name.to_sym) unless schema.nil?
		end
		raise "Unable to find table \"#{table_name}\""
	end

	def map_fields(from_table, to_table)
		mapping = {}

		from_words = {}
		from_table.fields.each do |symbol, field|
			from_words[symbol] = split_into_words(symbol.to_s)
		end

		to_words = {}
		to_table.fields.each do |symbol, field|
			to_words[symbol] = split_into_words(symbol.to_s)
			mapping[symbol] = nil
		end

		compare(mapping, to_words, from_words) do |m, to_list, from_list|
			is_exact_match?(m, to_list, from_list)
		end
		compare(mapping, to_words, from_words) do |m, to_list, from_list|
			is_closer_match?(m, to_list, from_list)
		end
		compare(mapping, to_words, from_words) do |m, to_list, from_list|
			is_close_match?(m, to_list, from_list)
		end
		return mapping
	end

	def compare(mapping, to_words, from_words, &block)
		to_words.each do |to_symbol, to_list|
			next unless mapping[to_symbol].nil?
			from_words.each do |from_symbol, from_list|
				if block.call(mapping, to_list, from_list)
					mapping[to_symbol] = from_symbol
					break
				end
			end
		end
	end

	def is_exact_match?(mapping, to_list, from_list)
		hits, misses, extra = tally_matches(to_list, from_list)
		return misses < 1 && hits > 1 && extra < 1
	end

	def is_closer_match?(mapping, to_list, from_list)
		hits, misses, extra = tally_matches(to_list, from_list)
		return misses < 1 && (hits > 1 || extra < 1)
	end

	def is_close_match?(mapping, to_list, from_list)
		hits, misses, extra = tally_matches(to_list, from_list)
		return misses < 2 && (hits > 1 || extra < 1)
	end

	def tally_matches(to_list, from_list)
		hits = misses = 0
		to_list.each do |to_word|
			if from_list.include?(to_word)
				hits += 1
			else
				misses += 1
			end
		end
		return hits, misses, from_list.count - hits
	end

	def split_into_words(name)
		name = name.gsub(/(\D+)(\d+)/, '\1_\2')
		parts = name.split(/_+/)
		parts.map! { |word| replace_word(word) }
		parts.reject! { |word| reject_word(word) }
		return parts.flatten
	end

	def reject_word(word)
		@@rejects[word] || false
	end

	def replace_word(word)
		@@replacements[word] || word
	end

	@@rejects = {
			'and' => true,
			'for' => true,
			'of' => true,
			'on' => true,
			'or' => true,
	}

	@@replacements = {
			'1st' => '1',
			'2nd' => '2',
			'3rd' => '3',
			'4th' => '4',
			'5th' => '5',
			'6th' => '6',
			'7th' => '7',
			'8th' => '8',
			'9th' => '9',
	    'alt' => 'alternate',
	    'amt' => 'amount',
	    'beg' => 'begin',
	    'cd' => 'code',
	    'desc' => 'description',
	    'descr' => 'description',
	    'dep' => 'dependent',
	    'diag' => 'diagnosis',
	    'div' => 'division',
	    'dob' => ['date', 'of', 'birth'],
	    'dos' => ['date', 'of', 'service'],
	    'dt' => 'date',
	    'dx' => 'diagnosis',
	    'ee' => 'employee',
	    'eff' => 'effective',
	    'flg' => 'flag',
	    'frm' => 'from',
	    'grp' => 'group',
	    'id' => 'identifier',
	    'ip' => 'inpatient',
	    'ln' => 'line',
	    'loc' => 'location',
	    'mbr' => 'member',
	    'med' => 'medical',
	    'mi' => 'middle',
	    'mid' => 'middle',
	    'mod' => 'modifier',
	    'nbr' => 'number',
	    'ndc' => ['national', 'drug', 'code'],
	    'nm' => 'name',
	    'no' => 'number',
	    'num' => 'number',
	    'op' => 'outpatient',
	    'org' => 'organization',
	    'orig' => 'original',
	    'pd' => 'paid',
	    'phys' => 'physician',
	    'poa' => ['present', 'on', 'admission'],
	    'pos' => ['place', 'of', 'service'],
	    'pri' => 'primary',
	    'proc' => 'procedure',
	    'prov' => 'provider',
	    'prv' => 'provider',
	    'qty' => 'quantity',
	    'rel' => 'relationship',
	    'rev' => 'revenue',
	    'rx' => 'drug',  # 'pharmacy',
	    'sec' => 'secondary',
	    'seq' => 'sequence',
	    'serv' => 'service',
	    'sex' => 'gender',
	    'spec' => 'specialty',
	    'st' => 'state',
	    'svc' => 'service',
	    'term' => 'termination',
	    'thr' => 'through',
	    'thru' => 'through',
	    'tob' => ['type', 'of', 'bill'],
	    'tot' => 'total',
	    'typ' => 'type',
	    'un' => 'units',
	    'val' => 'value',
	    'ver' => 'version',
	    'zip' => ['zip', 'code']
	}

	def parse_options(opts)
		opts.banner = "Usage: #{$0} sql [OPTIONS] --from FORMATFILE [--from_schema SCHEMACLASS] --from_table TABLENAME [--to FORMATFILE] [--to_schema SCHEMACLASS] --to_table TABLENAME"
		opts.separator ''
		opts.separator 'Generates a sql insert statement from one table to another'
		opts.separator ''
		opts.separator 'OPTIONS:'

		opts.on('--from FORMATFILE', 'format filename') do |value|
			@from_format = split_args(value)
		end

		opts.on('--from_schema SCHEMANAME', 'fully qualified schema classname') do |value|
			@from_schema = value
		end

		opts.on('--from_table TABLENAME', 'table name') do |value|
			@from_table = value
		end

		opts.on('--to FORMATFILE', 'format filename') do |value|
			@to_format = split_args(value)
		end

		opts.on('--to_schema SCHEMANAME', 'fully qualified schema classname') do |value|
			@to_schema = value
		end

		opts.on('--to_table TABLENAME', 'table name') do |value|
			@to_table = value
		end

		parse_def_options opts

		# Verify arguments
	end

end
end
