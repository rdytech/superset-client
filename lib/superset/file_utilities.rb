module Superset
  module FileUtilities
    # rubyzip is loaded lazily so the gem can be required without it; only
    # consumers that actually import/export need rubyzip installed (NEP-21211).
    def unzip_file(zip_file, destination)
      require 'zip'
      entries = []
      Zip::File.open(zip_file) do |zip|
        zip.each do |entry|
          next if entry.name.empty?

          entry_path = File.join(destination, entry.name)
          entries << entry_path
          FileUtils.mkdir_p(File.dirname(entry_path))

          zip.extract(entry, entry.name, destination_directory: destination) { true }
        rescue => e
          raise "Error extracting file #{entry.name}: #{e.message}"
        end
      end

      entries
    end
  end
end
