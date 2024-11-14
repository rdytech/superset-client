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
        logger.info("Exporting dashboard: #{dashboard_id}")
        create_tmp_dir
        save_exported_zip_file
        unzip_files
        clean_destination_directory
        copy_export_files_to_destination_path if destination_path

        Dir.glob("#{destination_path_with_dash_id}/**/*").select { |f| File.file?(f) }
      rescue StandardError => e
        raise
      ensure
        cleanup_temp_dir
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
        logger.info("Saving zip file: #{zip_file_name}")
        File.open(zip_file_name, 'wb') { |fp| fp.write(response.body) }
      end

      def unzip_files
        logger.info("Unzipping file: #{zip_file_name}")
        @extracted_files = unzip_file(zip_file_name, tmp_uniq_dashboard_path)
      end

      def download_folder
        File.dirname(extracted_files[0])
      end

      def destination_path_with_dash_id
        @destination_path_with_dash_id ||= File.join(destination_path, dashboard_id.to_s)
      end

      def clean_destination_directory
        logger.info("Cleaning destination directory: #{destination_path_with_dash_id}")
        if Dir.exist?(destination_path_with_dash_id)
          FileUtils.rm_rf(Dir.glob("#{destination_path_with_dash_id}/*"))
        else
          FileUtils.mkdir_p(destination_path_with_dash_id)
        end
      end

      def copy_export_files_to_destination_path
        logger.info("Copying files to destination: #{destination_path_with_dash_id}")
        path_with_dash_id = File.join(destination_path, dashboard_id.to_s)
        FileUtils.mkdir_p(path_with_dash_id) unless File.directory?(path_with_dash_id)
        FileUtils.cp(zip_file_name, path_with_dash_id)

        Dir.glob("#{download_folder}/*").each do |item|
          FileUtils.cp_r(item, path_with_dash_id)
        end
      end

      def cleanup_temp_dir
        if Dir.exist?(tmp_uniq_dashboard_path)
          FileUtils.rm_rf(tmp_uniq_dashboard_path)
        end
      end

      def create_tmp_dir
        logger.info("Creating tmp directory: #{tmp_uniq_dashboard_path}")
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
        raise
      end
    end

    def logger
      @logger ||= Superset::Logger.new
    end
  end
end
