=begin
Superset::Services::ImportDashboardAcrossEnvironments

This service is used to duplicate a dashboard from one environment to another.
It will not create any database connections from an imported dashboard zip, therefore the target database yml configuration
must already exist in the target superset environment.

Currently handles only 1 Database yaml file in the zip file. ( ie only 1 common database connection per dashboards datasets )

Requirements: 
 - target_database_yaml_file
 - target_database_schema
 - dashboard_export_zip

Usage:
Assuming you have exported a dashboard from the source environment and have the zip file, and have exported the target database yaml file
Superset::Services::ImportDashboardAcrossEnvironments.new(
 target_database_yaml_file: '/tmp/database.yaml',
 target_database_schema: 'insert_schema_here',
 dashboard_export_zip: '/tmp/dashboard.zip'
).perform

=end

#require 'superset/file_utilities'
require 'yaml'

module Superset
  module Services
    class ImportDashboardAcrossEnvironments
#      include FileUtilities

      attr_reader :target_database_yaml_file, :target_database_schema, :dashboard_export_zip

      def initialize(target_database_yaml_file:, target_database_schema: ,dashboard_export_zip:)
        @target_database_yaml_file   = target_database_yaml_file
        @target_database_schema = target_database_schema
        @dashboard_export_zip        = dashboard_export_zip
      end

      def perform
        validate_params

        remove_source_database_config
        insert_target_database_file
        insert_target_database_config
        update_dataset_configs

        create_new_dashboard_zip
      end

      private

      def dashboard_config
        @dashboard_config ||= Superset::Services::DashboardLoader.new(dashboard_export_zip: dashboard_export_zip).perform
      end

      def remove_source_database_config
        return if dashboard_config[:databases].blank?
        previous_database_name = dashboard_config[:databases]&.first[:content][:database_name]
        File.delete(dashboard_config[:databases].first[:filename])

        dashboard_config[:databases].clear
      end

      def insert_target_database_file
        FileUtils.cp(target_database_yaml_file, File.join(dashboard_export_root_path, 'databases'))

        pattern = File.join(dashboard_export_root_path, 'databases', '*.yaml')
        @new_database_yaml_file_path = Dir.glob(pattern).first
      end

      def insert_target_database_config
        yaml_content = YAML.load_file(target_database_yaml_file).deep_symbolize_keys
        dashboard_config[:databases] << { filename: new_database_yaml_file_path, content: yaml_content }
      end

      def update_dataset_configs
        dashboard_config[:datasets].each do |dataset|
          dataset[:content][:database_uuid] = dashboard_config[:databases].first[:content][:uuid]
          dataset[:content][:schema]        = target_database_schema
          File.open(dataset[:filename], 'w') { |f| f.write dataset[:content].to_yaml }
        end
      end

      def create_new_dashboard_zip
        Zip::File.open(new_zip_file, Zip::File::CREATE) do |zipfile|
          Dir[File.join(dashboard_export_root_path, '**', '**')].each do |file|
            zipfile.add(file.sub(dashboard_export_root_path + '/', File.basename(dashboard_export_root_path) + '/' ), file) if File.file?(file)
          end
        end
        new_zip_file
      end

      def new_zip_file
        new_database_name = dashboard_config[:databases].first[:content][:database_name]
        File.join(dashboard_config[:tmp_uniq_dashboard_path], "dashboard_import_for_#{new_database_name}.zip")
      end

      def new_database_yaml_file_path
        @new_database_yaml_file_path ||= ''
      end

      def dashboard_export_root_path
        # locate the unziped dashboard_export_* directory as named by superset app, eg dashboard_export_20240821T001536
        @dashboard_export_root_path ||= begin 
          pattern = File.join(dashboard_config[:tmp_uniq_dashboard_path], 'dashboard_export_*')
          Dir.glob(pattern).first
        end

      end

      def new_database_name
        dashboard_config[:databases].first[:content][:database_name]
      end

      def previous_database_name
        @previous_database_name ||= ''
      end

      def validate_params
        raise "Dashboard Export Zip file does not exist" unless File.exist?(dashboard_export_zip)
        raise "Target Database YAML file does not exist" unless File.exist?(target_database_yaml_file)
        raise "Only 1 Database YAML file is allowed in the zip file" if dashboard_config[:databases].size > 1
        raise "Target Database Schema cannot be blank" if target_database_schema.blank?
      end
    end
  end
end
