require 'zip'

module Superset
  module FileUtilities
    def unzip_file(zip_file, destination)
      entries = []
      Zip::File.open(zip_file) do |zip|
        zip.each do |entry|
          next if entry.name.empty?

          entry_path = File.join(destination, entry.name)
          entries << entry_path
          FileUtils.mkdir_p(File.dirname(entry_path))

          # RubyZip 3.x: destination_directory must allow our absolute entry_path.
          # Default '.' makes extract_path fail start_with?(dest_dir) and skip extraction.
          zip.extract(entry, entry_path, destination_directory: '/') unless File.exist?(entry_path)
        rescue => e
          raise "Error extracting file #{entry.name}: #{e.message}"
        end
      end

      entries
    end
  end
end
