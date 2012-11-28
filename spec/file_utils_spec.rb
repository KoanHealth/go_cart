require 'spec_helper'
require 'date'

describe "Inspect CSV files" do

  def data_file(filename)
	  return File.join(File.dirname(File.expand_path(__FILE__)), "data", filename)
  end

	def check_csv_options(hash)
		hash.each do |filename, options|
			begin
		    calculated_options = GoCart::FileUtils.get_csv_options(filename)
				options.each do |key, value|
					calculated_options[key].should == options[key]
				end
	    rescue
		    raise unless options == :exception
	    end
		end
	end

	before(:all) do
		@samples = Dir[data_file("sample??_*.txt")].sort
	end

  it "should detect CSV options" do
	  sample = @files
	  check_csv_options(
		  {
				@samples[0] => :exception,
				@samples[1] => { headers: true, col_sep: ',' },
			  @samples[2] => { headers: true, col_sep: ',' },
			  @samples[3] => { headers: false, col_sep: ',' },
			  @samples[4] => { headers: false, col_sep: ',' },
			  @samples[5] => { headers: true, col_sep: ',' },
			  @samples[6] => { headers: true, col_sep: '|' },
			  @samples[7] => :exception,
			}
	  )
  end

	it "should get headers" do
		headers = GoCart::FileUtils.get_headers(@samples[1])
		headers.should == [ 'A', 'B', 'C', 'D' ]
	end

end