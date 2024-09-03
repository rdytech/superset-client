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

      TMP_SUPERSET_DASHBOARD_PATH = '/tmp/superset_dashboards'

      attr_reader :dashboard_id, :destination_path

      def initialize(dashboard_id: , destination_path: )
        @dashboard_id = dashboard_id
        @destination_path = destination_path.chomp('/')
      end

      def perform
        create_tmp_dir
        save_exported_zip_file
        unzip_files
        copy_export_files_to_destination_path if destination_path
      end

      def response
        @response ||= client.call(
          :get,
          client.url(route),
          client.param_check(params)
        )
      end

      private

      def params
        { "q": "!(#{dashboard_id})" }   # pulled off chrome dev tools doing a GUI export.  Swagger interface not helpfull with this endpoint.
      end

      def save_exported_zip_file
        File.open(zip_file_name, 'wb') { |fp| fp.write(response.body) }
      end

      def unzip_files
        @extracted_files = unzip_file(zip_file_name, tmp_uniq_dashboard_path)
      end

      def download_folder
        File.dirname(extracted_files[0])
      end

      def copy_export_files_to_destination_path
        path_with_dash_id = File.join(destination_path, dashboard_id.to_s)
        FileUtils.mkdir_p(path_with_dash_id) unless File.directory?(path_with_dash_id)

        Dir.glob("#{download_folder}/*").each do |item|
          FileUtils.cp_r(item, path_with_dash_id)
        end
      end

      def zip_file_name
        @zip_file_name ||= "#{tmp_uniq_dashboard_path}/dashboard_#{dashboard_id}_export_#{datestamp}.zip"
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
    end
  end
end
