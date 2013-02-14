require 'spec_helper'

module GoCart
  describe GeneratorFromSchema do

    let (:schema_file) { DataHelper.find_data_file "schemas/claims.txt" }
    let (:dup_fields_schema_file) { DataHelper.find_data_file "schemas/dup_fields.txt" }
    let (:template_dir) { File.expand_path File.join(File.dirname(__FILE__), '..', 'data', filename) }
    let (:generator) do
      generator = GeneratorFromSchema.new
      generator.template_directory = DataHelper.template_directory
      generator
    end

    it 'should read the header information' do
      generator.generate schema_file
      generator.send(:module_name).should eq 'Tester_Claim'
      generator.send(:current_format).name.should eq 'Tester'
      generator.send(:current_format_table).name.should eq 'Tester Claim'
      generator.send(:current_schema).name.should eq 'Tester'
      generator.send(:current_schema_table).symbol.should eq :tester_claim
    end

    it 'should fail if schema file missing' do
      -> { generator.generate nil }.should raise_error 'Schema file is required'
    end

    it 'should fail if schema has duplicate fields' do
      -> { generator.generate dup_fields_schema_file }.should raise_error 'Duplicate field: product_id'
    end

  end
end