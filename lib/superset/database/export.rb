# Will export the Database zip file to /tmp/superset_database_exports with zip filename adjusted to include the database_id
# Example zipfile: dashboard_#{database_id}_export_#{datestamp}.zip
#
# File will then be unziped and all files copied into the destination_path with the database_id as a subfolder
# Optianally remove the dataset yaml files from the export
#
# Usage
# Superset::Database::Export.new(database_id: 15, destination_path: '/tmp/superset_database_exports/').perform

# Superset::Database::Export.new(database_id: 15, destination_path: '/tmp/superset_database_exports/', remove_dataset_yamls: true).perform
#

require 'superset/file_utilities'

module Superset
  module Database
    class Export < Request
      include FileUtilities

      TMP_SUPERSET_DATABASE_PATH = '/tmp/superset_database_exports'.freeze

      attr_reader :database_id, :destination_path, :remove_dataset_yamls

      def initialize(database_id: , destination_path: , remove_dataset_yamls: true)
        @database_id = database_id
        @destination_path = destination_path.chomp('/')
        @remove_dataset_yamls = remove_dataset_yamls
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

      def exported_zip_path
        @exported_zip_path ||= "#{tmp_uniq_database_path}/database_#{database_id}_export_#{datestamp}.zip"
      end

      private

      def params
        { "q": "!(#{database_id})" }   # pulled off chrome dev tools doing a GUI export.  Swagger interface not helpfull with this endpoint.
      end

      def save_exported_zip_file
        File.open(exported_zip_path, 'wb') { |fp| fp.write(response.body) }
      end

      def unzip_files
        @extracted_files = unzip_file(zip_file_name, tmp_uniq_database_path)
        remove_dataset_yaml_files if remove_dataset_yamls
      end

      def download_folder
        File.dirname(extracted_files[0])
      end

      def destination_path_with_db_id
        @destination_path_with_db_id ||= File.join(destination_path, database_id.to_s)
      end

      def copy_export_files_to_destination_path
        FileUtils.mkdir_p(destination_path_with_db_id) unless File.directory?(destination_path_with_db_id)

        Dir.glob("#{download_folder}/*").each do |item|
          FileUtils.cp_r(item, destination_path_with_db_id)
        end
      end

      def remove_dataset_yaml_files
        datasets_directories = Dir.glob( File.join(tmp_uniq_database_path, '/*/datasets') )

        # Iterate over each matching directory and remove it
        datasets_directories.each do |directory|
          FileUtils.rm_rf(directory) if Dir.exist?(directory)
        end
      end

      def create_tmp_dir
        FileUtils.mkdir_p(tmp_uniq_database_path) unless File.directory?(tmp_uniq_database_path)
      end

      # uniq random tmp folder name for each export
      # this will allow us to do a wildcard glop on the folder to get the files 
      def tmp_uniq_database_path
        @tmp_uniq_database_path ||= File.join(TMP_SUPERSET_DATABASE_PATH, uuid)
      end

      def uuid
        SecureRandom.uuid
      end

      def extracted_files
        @extracted_files ||= []
      end

      def route
        "database/export/"
      end

      def datestamp
        @datestamp ||= Time.now.strftime('%Y%m%d')
      end
    end
  end
end
