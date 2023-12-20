module Superset
  module Services
    class DuplicateDashboard < Request
      include FileUtilities

      attr_reader :template_dashboard_id, :schemas

      def initialize(template_dashboard_id: nil, schemas: [])
        @template_dashboard_id = template_dashboard_id
        @schemas = schemas
      end

      def perform
        # for each schema
        #   duplicate all export_config_path files to import_config_path
        #   read all import_config_path files
        #   replicate the config with new uuids and schema
        #   zip and import to superset
        #   delete the import_config_path files
        # end
        schemas.each do |schema|
          # duplicate all export_config_path files to import_config_path
          duplicate_export_files_to_import_folder(schema)
          # read all import_config_path files
          read_import_config_files(schema)
          # replicate the config with new uuids and schema
          # zip and import to superset
          # delete the import_config_path files

        end

      end

      def duplicate_export_files_to_import_folder(schema)
        export_config_files = Dir.glob(File.join(export_config_path, '**', '*.yaml'))
        export_config_files.each do |export_config_file|
          puts "Copying config file: #{export_config_file}"
          FileUtils.cp(export_config_file, import_config_path(schema))
        end
      end

      def response
        
      end

      # private
      def exporter
        @exporter ||= begin
          e = Superset::Dashboard::Export.new(dashboard_id: template_dashboard_id)
          e.perform
          e
        end
      end
    end
  end
end