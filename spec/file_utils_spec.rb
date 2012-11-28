require 'spec_helper'
require 'date'

describe "Detect Files" do

	def path
		return File.dirname(File.expand_path(__FILE__))
	end

  def data(filename)
	  return File.join(path, "data", filename)
  end

  def files()
	  return Dir[data("sample??_*.txt")].sort
  end

	def check_has_headers?(hash)
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

  it "should detect headers" do
	  sample = files
	  check_has_headers?(
		  {
			  sample[0] => :exception,
			  sample[1] => { headers: true, col_sep: ',' },
			  sample[2] => { headers: true, col_sep: ',' },
			  sample[3] => { headers: false, col_sep: ',' },
			  sample[4] => { headers: false, col_sep: ',' },
			  sample[5] => { headers: true, col_sep: ',' },
			  sample[6] => { headers: true, col_sep: '|' },
			  sample[7] => :exception,
			}
	  )
  end

	it "should get headers" do
		headers = GoCart::FileUtils.get_headers(data('sample01_lf.txt'))
		headers.should == [ 'A', 'B', 'C', 'D' ]
	end

end