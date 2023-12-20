# Use with DashboardExport.call(dashboard_id)
# It will export the zip file to the current folder as 'test.zip'
require 'superset/file_utilities'
require 'faraday'
require 'faraday/multipart'

module Superset
  module Dashboard
    class Import < Request
      include FileUtilities

       attr_reader :zip_file

      def initialize(zip_file: nil)
        @zip_file = zip_file
      end

      def perform
        response
      end

      def response
        filename = '/tmp/superset_dashboards/dashboard_import_20231218T050708.zip'
        @response ||= client.post(route, {
          formData: Faraday::UploadIO.new(filename, 'application/zip'),
          overwrite: false
        })
      end

      # private

      def client
        @client ||= begin
          c = Superset::Client.new
          c.connection =
            Faraday.new(c.superset_host) do |f|
              f.authorization :Bearer, c.access_token
              f.request :multipart
              f.adapter :net_http
            end
        end
      end


      def route
        "api/v1/dashboard/import/"
      end

    end
  end
end
