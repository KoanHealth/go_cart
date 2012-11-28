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
		hash.each do |filename, has_headers|
			begin
				puts filename
		    calculated_value = GoCart::FileUtils.has_headers?(filename)
		    calculated_value.should == has_headers
	    rescue
		    raise unless has_headers == :exception
	    end
		end
	end

  it "should detect headers" do
	  sample = files
	  check_has_headers?(
		  {
			  sample[0] => :exception,
			  sample[1] => true,
			  sample[2] => true,
			  sample[3] => false,
			  sample[4] => false,
			  sample[5] => true,
			  sample[6] => true,
			  sample[7] => :exception,
			}
	  )
  end

end