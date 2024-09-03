=begin
Superset::Services::ImportDashboardAcrossEnvironments

This service is used to duplicate a dashboard from one environment to another.
It will not create any database connections from an imported dashboard zip, therefore the target database yml configuration must already exist in the target environment.

Currently requires there be only 1 Database yaml file in the zip file. ( ie only 1 database connection per dashboard )

Requirements: 
 - target_database_yaml
 - source_zip_file

Usage:
Assuming you have exported a dashboard from the source environment and have the zip file, and the target database yaml file
Superset::Services::ImportDashboardAcrossEnvironments.new(
 target_database_yaml: '/tmp/database.yaml',
 target_database_schema: 'insert_schema_here',
 source_zip_file: '/tmp/dashboard.zip'
).perform

=end

require 'superset/file_utilities'
require 'yaml'

module Superset
  module Services
    class ImportDashboardAcrossEnvironments < Superset::Request
      include FileUtilities      

      TMP_PATH = '/tmp/superset_dashboard_imports'.freeze

      attr_reader :target_database_yaml, :target_database_schema, :source_zip_file

      def initialize(target_database_yaml:, target_database_schema: ,source_zip_file:)
        @target_database_yaml = target_database_yaml
        @target_database_schema = target_database_schema
        @source_zip_file = source_zip_file
      end

      def perform
        # validate source_zip_file, check if it exists
        # validate target_database_yaml, check if it exists
        # validate only 1 database yaml file in the zip file
        # validate the zip file .. confirming the datasets are valid, ie all datasets point to the same database uuid in the zip 
        # validate the target_database_schema exists in the target environment on the target database


        # unzip the source zip file to a tmp directory
        unzip_source_file

        # remove the source database yaml file
        remove_source_database_yaml_file

        # insert the target database yaml file into the tmp directory
        insert_target_database_yaml_file

        # update all dataset yamls with the target database yaml uuid value
        update_dataset_yamls_with_target_database_uuid_and_schema

        # zip the tmp directory
        zip_new_dashboard_config

        # upload the zip file
        import_new_dashboard_config

      end

      def import_new_dashboard_config
        Superset::Dashboard::Import.new(source_zip_file: new_zip_file, overwrite: true).perform
      end

      def remove_source_database_yaml_file
        pattern = File.join(tmp_uniq_dashboard_path, '**', 'databases', '*.yaml')
        Dir.glob(pattern).each do |file|
          if File.file?(file)
            File.delete(file)
            puts "Deleted file: #{file}"
          else
            puts "No file found for pattern: #{pattern}"
          end
        end
      end

      def insert_target_database_yaml_file
        # locate the dashboard_export directory, eg dashboard_export_20240821T001536
        pattern = File.join(tmp_uniq_dashboard_path, 'dashboard_export_*')
        dashboard_exports = Dir.glob(pattern)
        raise "No dashboard_export directory found for pattern: #{pattern}" if dashboard_exports.empty?
        raise "Multiple dashboard_export directories found for pattern: #{pattern}" if dashboard_exports.size > 1

        @dashboard_export_root_path = dashboard_exports.first
        FileUtils.cp(target_database_yaml, File.join(dashboard_exports.first, 'databases'))

        pattern = File.join(tmp_uniq_dashboard_path, '**', 'databases', '*.yaml')
        @new_database_yaml_file_path = Dir.glob(pattern).first
      end

      def update_dataset_yamls_with_target_database_uuid_and_schema
        all_dataset_yaml_files.each do |file|
          yaml_content = YAML.load_file(file)
          yaml_content['database_uuid'] = database_uuid
          yaml_content['schema'] = target_database_schema
          File.open(file, 'w') { |f| f.write yaml_content.to_yaml }
        end
      end

      def all_dataset_yaml_files
        pattern = File.join(tmp_uniq_dashboard_path, '**', 'datasets', '**', '*.yaml')
        Dir.glob(pattern)
      end

      def database_uuid
        @database_uuid ||= begin
          # read the new_database_yaml_file_path file to get the database uuid
          yaml_content = YAML.load_file(new_database_yaml_file_path)
          yaml_content['uuid']
      end
      end

      def unzip_source_file
        @extracted_files = unzip_file(source_zip_file, tmp_uniq_dashboard_path)
        #remove_database_yaml_file
      end

      def zip_new_dashboard_config        
        Zip::File.open(new_zip_file, Zip::File::CREATE) do |zipfile|
          Dir[File.join(dashboard_export_root_path, '**', '**')].each do |file|
            zipfile.add(file.sub(dashboard_export_root_path + '/', File.basename(dashboard_export_root_path) + '/' ), file) if File.file?(file)
          end

        end
      end

      def new_zip_file
        File.join(tmp_uniq_dashboard_path, 'new_dashboard_import.zip')
      end

      def new_database_yaml_file_path
        @new_database_yaml_file_path ||= ''
      end

      def dashboard_export_root_path
        @dashboard_export_root_path ||= ''
      end

      def tmp_uniq_dashboard_path
        @tmp_uniq_dashboard_path ||= File.join(TMP_PATH, uuid)
      end

      def uuid
        SecureRandom.uuid
      end
    end
  end
end
