require_relative 'go_cart_def'

module GoCart
class GoCartSql < GoCartDef

	attr_accessor :from_format, :from_schema, :from_table, :to_format, :to_schema, :to_table

	def execute()
		require @from_format
		require @to_format

		from_schema = get_instance(@from_schema)
		to_schema = get_instance(@to_schema)

		from_table = from_schema.get_table(@from_table.to_sym)
		to_table = to_schema.get_table(@to_table.to_sym)

		mapping = map_fields(from_table, to_table)
		template_directory = File.join(@script_dir, '../../templates')
		template = IO.read(File.join(template_directory, 'insert_select.sql.erb'))
		puts ERB.new(template).result(binding)
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
		end

		to_words.each do |to_symbol, to_list|
			mapping[to_symbol] = nil
			from_words.each do |from_symbol, from_list|
				hits = misses = 0
				to_list.each do |to_word|
					if from_list.include?(to_word)
						hits += 1
					else
						misses += 1
					end
				end
				extra = from_list.count - hits

				if misses >= 0 && (hits > 1 || extra < 1)
					mapping[to_symbol] = from_symbol
					next
				end
			end
		end

		return mapping
	end

	def split_into_words(name)
		name = name.gsub(/(.+)(\d+)/, '\1_\2')
		parts = name.split(/_+/)
		parts.reject! { |word| reject_word(word) }
		parts.map! { |word| replace_word(word) }
		return parts
	end

	@@rejects = {
			'and' => true,
			'for' => true,
			'of' => true,
			'on' => true,
			'or' => true,
	}

	def reject_word(word)
		return @@rejects[word] || false
	end

	@@replacements = {
	    'alt' => 'alternate',
	    'amt' => 'amount',
	    'beg' => 'begin',
	    'cd' => 'code',
	    'desc' => 'description',
	    'descr' => 'description',
	    'dep' => 'dependent',
	    'diag' => 'diagnosis',
	    'div' => 'division',
	    'dob' => 'birthdate',
	    'dt' => 'date',
	    'dx' => 'diagnosis',
	    'ee' => 'employee',
	    'eff' => 'effective',
	    'flg' => 'flag',
	    'grp' => 'group',
	    'id' => 'identifier',
	    'ln' => 'line',
	    'loc' => 'location',
	    'mbr' => 'member',
	    'med' => 'medical',
	    'mi' => 'middle',
	    'mid' => 'middle',
	    'mod' => 'modifier',
	    'nbr' => 'number',
	    'nm' => 'name',
	    'num' => 'number',
	    'org' => 'organization',
	    'orig' => 'original',
	    'pd' => 'paid',
	    'phys' => 'physician',
	    'pri' => 'primary',
	    'proc' => 'procedure',
	    'prov' => 'provider',
	    'prv' => 'provider',
	    'rel' => 'relationship',
	    'rev' => 'revenue',
	    'rx' => 'pharmacy',
	    'sec' => 'secondary',
	    'seq' => 'sequence',
	    'serv' => 'service',
	    'sex' => 'gender',
	    'spec' => 'specialty',
	    'st' => 'state',
	    'svc' => 'service',
	    'term' => 'termination',
	    'thru' => 'through',
	    'tot' => 'total',
	    'typ' => 'type',
	    'un' => 'units',
	    'val' => 'value',
	    'ver' => 'version',
	}

	def replace_word(word)
		return @@replacements[word] || word
	end

	def parse_options(opts)
		opts.banner = "Usage: #{$0} sql [OPTIONS] --from FORMATFILE --from_schema SCHEMACLASS --from_table TABLENAME --to FORMATFILE --to_schema SCHEMACLASS --to_table TABLENAME"
		opts.separator ''
		opts.separator 'Generates a sql insert statement from one table to another'
		opts.separator ''
		opts.separator 'OPTIONS:'

		opts.on('--from FORMATFILE', 'format filename') do |value|
			@from_format = value
		end

		opts.on('--from_schema SCHEMANAME', 'fully qualified schema classname') do |value|
			@from_schema = value
		end

		opts.on('--from_table TABLENAME', 'table name') do |value|
			@from_table = value
		end

		opts.on('--to FORMATFILE', 'format filename') do |value|
			@to_format = value
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
