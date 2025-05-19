# frozen_string_literal: true

# Import the provided Database zip file or directory (aka source)

# Scenario 1: Export from Env1 -- Import to Env1 into the SAME Environment
#             Will result in updating/over writing the database with the contents of the source

# Scenario 2: Export from Env1 -- Import to Env2 into a DIFFERENT Environment
#             Initial import will result in creating a new database with the contents of the source.
#             Subsequent imports will result in updating/over writing the previous imported database with the contents of the source.

# the overwrite flag will determine if the database will be updated or created new
# overwrite: false .. will result in an error if a database with the same UUID already exists

# Usage
# Superset::Database::Import.new(source: '/tmp/database.zip').perform
# Superset::Database::Import.new(source: '/tmp/database').perform
#

require "zip"
require "superset/file_utilities"

module Superset
  module Database
    class Import < Request
      include FileUtilities

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
      end

      def payload
        {
          formData: Faraday::UploadIO.new(source_zip_file, "application/zip"),
          overwrite: overwrite.to_s,
          passwords: "{}"
        }
      end

      def route
        "database/import/"
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
        database_name = database_config[:databases].first[:content][:database_name]
        File.join(source, "database_import.zip")
      end

      def database_config
        @database_config ||= zip? ? zip_database_config : directory_database_config
      end

      def zip_database_config
        Superset::Services::Loader.new(export_zip: source).perform
      end

      def directory_database_config
        Superset::Services::Loader::Config.new(
          export_zip: "", tmp_uniq_path: source
        ).config
      end
    end
  end
end
