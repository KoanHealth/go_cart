module FormatLoader
  def self.load_formats(formats)
    formats.each do |format|
      file_count = 0
      Dir.glob(File.expand_path(format)) do |format_file|
        require format_file
        file_count += 1
      end
      raise "Format files not found: #{format}" unless file_count > 0
    end
  end
end