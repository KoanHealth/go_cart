module DataHelper
  extend self

  def find_data_file(filename)
    path = File.join(current_directory, '..', 'data', filename)
    File.expand_path path
  end

  def open_data_file(filename)
    File.new(find_data_file(filename))
  end

  def template_directory
    @template_dir ||= File.expand_path(File.join(current_directory, '..', '..', 'templates'))
  end

  private

  def current_directory
    File.dirname(__FILE__)
  end


end