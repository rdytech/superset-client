# Will export the zip file to /tmp/superset_dashboards with zip filename adjusted to include the dashboard_id
# Example zipfile: dashboard_#{dashboard_id}_export_#{datestamp}.zip
# Will then unzip and copy the files into the destination_path with the dashboard_id as a subfolder
#
# Usage
# Superset::Dashboard::Export.new(dashboard_id: 15, destination_path: '/tmp/superset_dashboard_backups/').perform
#

require 'superset/file_utilities'

module Superset
  module Dashboard
    class Export < Request
      include FileUtilities

      TMP_SUPERSET_DASHBOARD_PATH = '/tmp/superset_dashboard_exports'

      attr_reader :dashboard_id, :destination_path

      def initialize(dashboard_id: , destination_path: )
        @dashboard_id = dashboard_id
        @destination_path = destination_path.chomp('/')
      end

      def perform
        puts "Starting export for dashboard ID: #{@dashboard_id}"
        create_tmp_dir
        puts "Temporary directory created at: #{tmp_uniq_dashboard_path}"

        save_exported_zip_file
        puts "Exported zip file saved at: #{zip_file_name}"

        unzip_files
        puts "Files unzipped to: #{tmp_uniq_dashboard_path}"

        copy_export_files_to_destination_path if destination_path
        puts "Files copied to destination: #{destination_path_with_dash_id}"

        cleanup_outdated_files
        puts "Cleanup of outdated files completed."

        Dir.glob("#{destination_path_with_dash_id}/**/*")
      rescue => e
        puts "Export failed: #{e.message}"
        raise
      end

      def response
        @response ||= client.call(
          :get,
          client.url(route),
          client.param_check(params)
        )
      end

      def zip_file_name
        @zip_file_name ||= "#{tmp_uniq_dashboard_path}/dashboard_#{dashboard_id}_export_#{datestamp}.zip"
      end

      private

      def params
        { "q": "!(#{dashboard_id})" }   # pulled off chrome dev tools doing a GUI export.  Swagger interface not helpfull with this endpoint.
      end

      def save_exported_zip_file
        File.open(zip_file_name, 'wb') { |fp| fp.write(response.body) }
        puts "Saved zip file: #{zip_file_name}"
      end

      def unzip_files
        @extracted_files = unzip_file(zip_file_name, tmp_uniq_dashboard_path)
        puts "Unzipped files: #{@extracted_files.inspect}"
      end

      def download_folder
        File.dirname(extracted_files[0])
      end

      def destination_path_with_dash_id
        @destination_path_with_dash_id ||= File.join(destination_path, dashboard_id.to_s)
      end

      def copy_export_files_to_destination_path
        FileUtils.mkdir_p(destination_path_with_dash_id) unless File.directory?(destination_path_with_dash_id)
        puts "Ensured destination directory: #{destination_path_with_dash_id}"

        Dir.glob("#{download_folder}/**/*").each do |item|
          next if File.directory?(item) # Skip directories

          relative_item_path = Pathname.new(item).relative_path_from(Pathname.new(download_folder)).to_s
          destination_item = File.join(destination_path_with_dash_id, relative_item_path)

          FileUtils.mkdir_p(File.dirname(destination_item)) unless File.directory?(File.dirname(destination_item))
          puts "Copying #{item} to #{destination_item}"
          FileUtils.cp(item, destination_item) # Using cp instead of cp_r
        end
      end

      def cleanup_outdated_files
        destination = Pathname.new(destination_path_with_dash_id)
        puts "Cleaning up outdated files in #{destination}"

        # Gather a list of relative paths from the download_folder, including only files
        latest_files = Dir.glob("#{download_folder}/**/*").select { |f| File.file?(f) }.map do |file|
          Pathname.new(file).relative_path_from(Pathname.new(download_folder)).to_s.downcase
        end
        puts "Latest files: #{latest_files.inspect}"

        # Convert latest_files to a Set for efficient lookup
        latest_files_set = latest_files.to_set

        # Iterate over existing files in the destination path and delete any that are not in the latest export
        Dir.glob("#{destination}/**/*").each do |existing_file|
          existing_path = Pathname.new(existing_file)
          next if existing_path.directory? # Skip directories

          relative_path = existing_path.relative_path_from(destination).to_s.downcase
          puts "Checking file: #{relative_path}"

          unless latest_files_set.include?(relative_path)
            puts "Removing file: #{existing_file} as it's not in the latest export."
            FileUtils.rm_f(existing_file)
          else
            puts "Retaining file: #{existing_file} as it's part of the latest export."
          end
        end
      end

      def create_tmp_dir
        FileUtils.mkdir_p(tmp_uniq_dashboard_path) unless File.directory?(tmp_uniq_dashboard_path)
      end

      # uniq random tmp folder name for each export
      # this will allow us to do a wildcard glop on the folder to get the files
      def tmp_uniq_dashboard_path
        @tmp_uniq_dashboard_path ||= File.join(TMP_SUPERSET_DASHBOARD_PATH, uuid)
      end

      def uuid
        SecureRandom.uuid
      end

      def extracted_files
        @extracted_files ||= []
      end

      def route
        "dashboard/export/"
      end

      def datestamp
        @datestamp ||= Time.now.strftime('%Y%m%d')
      end

      def unzip_file(zip_path, destination)
        extracted_files = []
        Zip::File.open(zip_path) do |zip_file|
          zip_file.each do |entry|
            entry_path = File.join(destination, entry.name)
            FileUtils.mkdir_p(File.dirname(entry_path))
            zip_file.extract(entry, entry_path) unless File.exist?(entry_path)
            extracted_files << entry_path
          end
        end
        extracted_files
      rescue => e
        puts "Failed to unzip file: #{e.message}"
        raise
      end
    end
  end
end
