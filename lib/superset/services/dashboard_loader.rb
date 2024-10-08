# Given a path, load all yaml files

require 'superset/file_utilities'
require 'yaml'

module Superset
  module Services
    class DashboardLoader
      include FileUtilities

      TMP_PATH = '/tmp/superset_dashboard_imports'.freeze

      attr_reader :dashboard_export_zip

      def initialize(dashboard_export_zip:)
        @dashboard_export_zip = dashboard_export_zip
      end

      def perform
        unzip_source_file
        dashboard_config
      end

      def dashboard_config
        @dashboard_config ||= DashboardConfig.new(
                                dashboard_export_zip:    dashboard_export_zip, 
                                tmp_uniq_dashboard_path: tmp_uniq_dashboard_path).config
      end

      private

      def unzip_source_file
        @extracted_files = unzip_file(dashboard_export_zip, tmp_uniq_dashboard_path)
      end

      def tmp_uniq_dashboard_path
        @tmp_uniq_dashboard_path ||= File.join(TMP_PATH, uuid)
      end

      def uuid
        SecureRandom.uuid
      end

      class DashboardConfig < ::OpenStruct
        def config
            {
              tmp_uniq_dashboard_path: tmp_uniq_dashboard_path,
              dashboards: load_yamls_for('dashboards'),
              databases:  load_yamls_for('databases'),
              datasets:   load_yamls_for('datasets'),
              charts:     load_yamls_for('charts'),
              metadata:   load_yamls_for('metadata.yaml', pattern_sufix: nil),
            }
        end

        def load_yamls_for(object_path, pattern_sufix: '**/*.yaml')
          pattern = File.join([tmp_uniq_dashboard_path, '**', object_path, pattern_sufix].compact)
          Dir.glob(pattern).map do |file|
            { filename: file, content: load_yaml_and_symbolize_keys(file) } if File.file?(file)
          end.compact
        end

        def load_yaml_and_symbolize_keys(path)
          YAML.load_file(path).deep_symbolize_keys
        end
      end
    end
  end
end
