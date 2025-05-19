# frozen_string_literal: true

# Import the provided Dashboard zip file or directory (aka source)
# In the context of this API import process, assumption is that the database.yaml file details will match
# an existing database in the Target Superset Environment.

# Scenario 1: Export from Env1 -- Import to Env1 into the SAME Environment
#             Will result in updating/over writing the dashboard with the contents of the source

# Scenario 2: Export from Env1 -- Import to Env2 into a DIFFERENT Environment
#             Assumption is that the database.yaml will match a database configuration in the target env.
#             Initial import will result in creating a new dashboard with the contents of the source.
#             Subsequent imports will result in updating/over writing the previous imported dashboard with the contents of the source.

# the overwrite flag will determine if the dashboard will be updated or created new
# overwrite: false .. will result in an error if a dashboard with the same UUID already exists

# Usage
# Superset::Dashboard::Import.new(source: '/tmp/dashboard.zip').perform
# Superset::Dashboard::Import.new(source: '/tmp/dashboard').perform
#

module Superset
  module Dashboard
    class Import < Request
      attr_reader :source, :overwrite

      def initialize(source:, overwrite: true)
        @source = source
        @overwrite = overwrite
      end

      def perform
        validate_params
        response
      end

      def response
        @response ||= client(use_json: false).post(
          route,
          payload
        )
      end

      private

      def validate_params
        raise ArgumentError, "source is required" if source.nil?
        raise ArgumentError, "source does not exist" unless File.exist?(source)
        raise ArgumentError, "source is not a zip file or directory" unless zip? || directory?
        raise ArgumentError, "overwrite must be a boolean" unless [true, false].include?(overwrite)

        return unless database_config_not_found_in_superset.present?

        raise ArgumentError,
              "target database does not exist: #{database_config_not_found_in_superset}"
      end

      def payload
        {
          formData: Faraday::UploadIO.new(source_zip_file, "application/zip"),
          overwrite: overwrite.to_s
        }
      end

      def route
        "dashboard/import/"
      end

      def zip?
        File.extname(source) == ".zip"
      end

      def directory?
        File.directory?(source)
      end

      def source_zip_file
        return source if zip?

        Zip::File.open(new_zip_file, Zip::File::CREATE) do |zipfile|
          Dir[File.join(source, "**", "**")].each do |file|
            zipfile.add(file.sub("#{source}/", "#{File.basename(source)}/"), file) if File.file?(file)
          end
        end
        new_zip_file
      end

      def new_zip_file
        new_database_name = dashboard_config[:databases].first[:content][:database_name]
        File.join(source, "dashboard_import.zip")
      end

      def database_config_not_found_in_superset
        databases_details.reject { |s| superset_database_uuids_found.include?(s[:uuid]) }
      end

      def superset_database_uuids_found
        @superset_database_uuids_found ||= databases_details.map { |i| i[:uuid] }.map do |uuid|
          uuid if Superset::Database::List.new(uuid_equals: uuid).result.present?
        end.compact
      end

      def databases_details
        dashboard_config[:databases].map { |d| { uuid: d[:content][:uuid], name: d[:content][:database_name] } }
      end

      def dashboard_config
        @dashboard_config ||= zip? ? zip_dashboard_config : directory_dashboard_config
      end

      def zip_dashboard_config
        Superset::Services::DashboardLoader.new(dashboard_export_zip: source).perform
      end

      def directory_dashboard_config
        Superset::Services::DashboardLoader::DashboardConfig.new(
          dashboard_export_zip: "", tmp_uniq_dashboard_path: source
        ).config
      end
    end
  end
end
