require 'spec_helper'
require 'mappers/four_column_mapping'

module GoCart

  describe LoaderFromCsv do

    def data_file(filename)
      return File.join(File.dirname(File.expand_path(__FILE__)), '../sample_data', filename)
    end

    describe 'When loading a file with headers' do
      let(:file_name) { data_file 'sample_with_headers.txt' }
      let(:format_table) { FourColumnMapping::Format.new.get_table :header }
      let(:converter) {RawTableConverter.new(format_table)}

      it 'should yield 16 rows' do
        count = 0
        LoaderFromCsv.new().load(file_name, format_table) {count += 1}
        count.should eq 16
      end

      it 'should provide expected data for each row' do
        LoaderFromCsv.new().load(file_name, format_table) do |raw|
          row = converter.convert(raw)
          row[:a].should eq '1'
          row[:b].should eq '2'
          row[:c].should eq 3
          row[:d].should eq 4
        end
      end
    end

    describe 'When loading a file without headers' do
      let(:file_name) { data_file 'sample_without_headers.txt' }
      let(:format_table) { FourColumnMapping::Format.new.get_table :no_header }
      let(:converter) {RawTableConverter.new(format_table)}

      it 'should yield 16 rows' do
        count = 0
        LoaderFromCsv.new().load(file_name, format_table) {count += 1}
        count.should eq 16
      end

      it 'should provide expected data for each row' do
        LoaderFromCsv.new().load(file_name, format_table) do |raw|
          row = converter.convert(raw)

          row[:a].should eq '1'
          row[:b].should eq '2'
          row[:c].should eq 3
          row[:d].should eq 4
        end
      end
    end

    describe 'When loading a file without headers (and cr/lf endings)' do
      let(:file_name) { data_file 'sample_without_headers_cr_lf.txt' }
      let(:format_table) { FourColumnMapping::Format.new.get_table :no_header }
      let(:converter) {RawTableConverter.new(format_table)}

      it 'should yield 16 rows' do
        count = 0
        LoaderFromCsv.new().load(file_name, format_table) {count += 1}
        count.should eq 16
      end

      it 'should provide expected data for each row' do
        LoaderFromCsv.new().load(file_name, format_table) do |raw|
          row = converter.convert(raw)

          row[:a].should eq '1'
          row[:b].should eq '2'
          row[:c].should eq 3
          row[:d].should eq 4
        end
      end
    end
  end
end
