require 'spec_helper'

module GoCart
describe 'Schema' do

  def check_em(table, test_data)
    table.fields.each do |symbol, field|
      length = field.limit
      test_data.each do |text|
        if length.odd?  # Odd fields truncate
          result = field.format_value(text)
          next if text.nil? && result.nil?
          result.length.should == [text.length, length].min
        else  # Even fields do not truncate
          result = field.format_value(text)
          next if text.nil? && result.nil?
          (result.length != length || text.length == length).should be true
        end
      end
    end
  end

  let (:schema_file_string) { DataHelper.find_data_file "schemas/fixed_string.txt" }
  let (:schema_file_text) { DataHelper.find_data_file "schemas/fixed_text.txt" }

  def load_schema(schema_file, template_dir, output_dir, options = {})
    generator = GeneratorFromSchema.new
    generator.template_directory = template_dir
    format_file = File.join(output_dir, File.basename(schema_file, '.txt') + '.rb')
    generator.generate(schema_file, format_file, options)
    FormatLoader.load_formats([format_file])
  end

  it 'should format fixed length string values in schema' do
    template_dir = File.expand_path File.join(File.dirname(__FILE__), '..', 'templates')
    Dir.mktmpdir do |temp_dir|
      load_schema(schema_file_string, template_dir, temp_dir)
      table = FixedString::FixedStringSchema.new.get_table(:fixed_string)
      check_em(table, %w(1 12 123 1234 12345) << nil)
    end
  end

  it 'should format fixed length text values in schema' do
    template_dir = File.expand_path File.join(File.dirname(__FILE__), '..', 'templates')
    Dir.mktmpdir do |temp_dir|
      load_schema(schema_file_text, template_dir, temp_dir)
      table = FixedText::FixedTextSchema.new.get_table(:fixed_text)
      check_em(table, %w(1 12 123 1234 12345) << nil)
    end
  end

end
end
