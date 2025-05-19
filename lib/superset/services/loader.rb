# Given a path, load all yaml files

require "superset/file_utilities"
require "yaml"

module Superset
  module Services
    class Loader
      include FileUtilities

      TMP_PATH = "/tmp/superset_imports".freeze

      attr_reader :export_zip

      def initialize(export_zip:)
        @export_zip = export_zip
      end

      def perform
        unzip_source_file
        config
      end

      def config
        @config ||= Config.new(
          export_zip: export_zip,
          tmp_uniq_path: tmp_uniq_path
        ).config
      end

      private

      def unzip_source_file
        @extracted_files = unzip_file(export_zip, tmp_uniq_path)
      end

      def tmp_uniq_path
        @tmp_uniq_path ||= File.join(TMP_PATH, uuid)
      end

      def uuid
        SecureRandom.uuid
      end

      class Config < ::OpenStruct
        def config
          {
            tmp_uniq_path: tmp_uniq_path,
            dashboards: load_yamls_for("dashboards"),
            databases: load_yamls_for("databases"),
            datasets: load_yamls_for("datasets"),
            charts: load_yamls_for("charts"),
            metadata: load_yamls_for("metadata.yaml", pattern_sufix: nil)
          }
        end

        def load_yamls_for(object_path, pattern_sufix: "**/*.yaml")
          pattern = File.join([tmp_uniq_path, "**", object_path, pattern_sufix].compact)
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
