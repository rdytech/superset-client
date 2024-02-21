module Superset
  module Dashboard
    class Copy < Superset::Request

      attr_reader :id, :duplicate_slices

      def initialize(id: nil, duplicate_slices: false)
        @id = id
        @duplicate_slices = duplicate_slices
      end

      def perform
        raise "Error: id integer is required" unless id.present? && id.is_a?(Integer)
        raise "Error: duplicate_slices must be a boolean" unless duplicate_slices_is_boolean?

        new_dashboard_id
      end

      def params
        {
          "css" => "{}",
          "dashboard_title" => "#{source_dashboard.title} (COPY)",
          "duplicate_slices" => duplicate_slices,
          "json_metadata" => source_dashboard_json_metadata_with_positions.to_json,
        }
      end

      private

      def response
        @response ||= client.post(route, params)
      end

      def new_dashboard_id
        response["result"]["id"]
      end

      def route
        "dashboard/#{id}/copy/"
      end
 
      def source_dashboard_json_metadata_with_positions
        # when copying a DB via the API, chart positions need to be nested under json_metadata
        # according to the GUI copy function  (as per dev tools investigation in browser)
        source_dashboard.json_metadata.merge(
          "positions" => source_dashboard.positions 
        )
      end

      def source_dashboard
        @source_dashboard ||= begin
          dash = Get.new(id)
          dash.response
          dash
        rescue => e
          raise "Error retrieving source dashboard #{e.message}"
        end
      end

      def duplicate_slices_is_boolean?
        [true, false].include?(duplicate_slices)
      end
    end
  end
end
