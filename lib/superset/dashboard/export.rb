# Use with DashboardExport.call(dashboard_id)
# It will export the zip file to the current folder as 'test.zip'

require 'superset/file_utilities'

module Superset
  module Dashboard
    class Export < Request
      include FileUtilities

      TMP_SUPERSET_DASHBOARD_PATH = '/tmp/superset_dashboards'

      attr_reader :dashboard_id, :duplicate_export_for_importing

      def initialize(dashboard_id: , duplicate_export_for_importing: false)
        @dashboard_id = dashboard_id
        @duplicate_export_for_importing = duplicate_export_for_importing
      end

      def perform
        response
        write_file_and_unzip
        duplicate_export_files_to_import_folder if duplicate_export_for_importing
      end

      def response
        @response ||= client.call(
          :get, 
          client.url(route), 
          client.param_check(build_params(dashboard_id)) 
        )
      end

      def export_folder
        File.dirname(extracted_files[0])
      end

      def import_folder
        File.dirname(extracted_files[0]).gsub("export", "import")
      end

      # private

      def route
        "dashboard/export/"
      end

      def build_params(dashboard_id)
        { "q": "!(#{dashboard_id})" }
      end

      def write_file_and_unzip
        create_tmp_dir
        File.open(zip_file_name, 'wb') { |fp| fp.write(@response.body) }

        @extracted_files = unzip_file(zip_file_name, TMP_SUPERSET_DASHBOARD_PATH)
        

      end


      def duplicate_export_files_to_import_folder
        FileUtils.cp_r(export_folder, import_folder)
      end

      def zip_file_name
        @zip_file_name ||= "#{TMP_SUPERSET_DASHBOARD_PATH}/dashboard_#{dashboard_id}_export_#{datestamp}.zip"
      end

      def create_tmp_dir
        FileUtils.mkdir_p(TMP_SUPERSET_DASHBOARD_PATH) unless File.directory?(TMP_SUPERSET_DASHBOARD_PATH)
      end 

      def extracted_files
        @extracted_files ||= []
      end

      def datestamp
        @datestamp ||= Time.now.strftime('%Y%m%d')
      end
    end
  end
end