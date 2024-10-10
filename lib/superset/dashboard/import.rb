# Import the provided Dashboard zip file
# In the context of this API import process, assumption is that the database.yaml file details will match
# an existing database in the Target Superset Environment.

# Scenario 1: Export from Env1 -- Import to Env1 into the SAME Environment
#             Will result in updating/over writing the dashboard with the contents of the zip file 

# Scenario 2: Export from Env1 -- Import to Env2 into a DIFFERENT Environment
#             Assumption is that the database.yaml will match a database configuration in the target env. 
#             Initial import will result in creating a new dashboard with the contents of the zip file. 
#             Subsequent imports will result in updating/over writing the previous imported dashboard with the contents of the zip file.

# the overwrite flag will determine if the dashboard will be updated or created new
# overwrite: false .. will result in an error if a dashboard with the same UUID already exists

# Usage
# Superset::Dashboard::Import.new(source_zip_file: '/tmp/dashboard.zip').perform
#

module Superset
  module Dashboard
    class Import < Request
      attr_reader :source_zip_file, :overwrite

      def initialize(source_zip_file: , overwrite: true)
        @source_zip_file = source_zip_file
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
        raise ArgumentError, 'source_zip_file is required' if source_zip_file.nil?
        raise ArgumentError, 'source_zip_file does not exist' unless File.exist?(source_zip_file)
        raise ArgumentError, 'source_zip_file is not a zip file' unless File.extname(source_zip_file) == '.zip'
        raise ArgumentError, 'overwrite must be a boolean' unless [true, false].include?(overwrite)
        raise ArgumentError, "zip target database does not exist: #{zip_database_config_not_found_in_superset}" if zip_database_config_not_found_in_superset.present?
      end

      def payload
        {
          formData: Faraday::UploadIO.new(source_zip_file, 'application/zip'),
          overwrite: overwrite.to_s
        }
      end

      def route
        "dashboard/import/"
      end

      def zip_database_config_not_found_in_superset
        zip_databases_details.select {|s| !superset_database_uuids_found.include?(s[:uuid]) }
      end

      def superset_database_uuids_found
        @superset_database_uuids_found ||= begin
          zip_databases_details.map {|i| i[:uuid]}.map do |uuid|
            uuid if Superset::Database::List.new(uuid_equals: uuid).result.count == 1
          end.compact
        end
      end

      def zip_databases_details
        zip_dashboard_config[:databases].map{|d| {uuid: d[:content][:uuid], name: d[:content][:database_name]} }
      end

      def zip_dashboard_config
        @zip_dashboard_config ||= Superset::Services::DashboardLoader.new(dashboard_export_zip: source_zip_file).perform
      end
    end
  end
end
