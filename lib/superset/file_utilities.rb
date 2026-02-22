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

          zip.extract(entry, entry_path, destination_directory: '/') unless File.exist?(entry_path)
        rescue => e
          raise "Error extracting file #{entry.name}: #{e.message}"
        end
      end

      entries
    end
  end
end
