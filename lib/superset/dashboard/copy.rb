
# TODO: some work to happen around TAGS still .. ie 'template' tag would indicate it tested and available to be copied.
# TODO: also need to ensoure that the embedded details are not duplicated across to the new dashboard

module Superset
  module Dashboard
    class Copy < Superset::Request

      attr_reader :source_dashboard_id, :duplicate_slices

      def initialize(source_dashboard_id: , duplicate_slices: false)
        @source_dashboard_id = source_dashboard_id
        @duplicate_slices = duplicate_slices # boolean indicates whether to duplicate charts OR keep the new dashboard pointing to the same charts as the original
      end

      def perform
        raise "Error: source_dashboard_id integer is required" unless source_dashboard_id.present? && source_dashboard_id.is_a?(Integer)
        raise "Error: duplicate_slices must be a boolean" unless duplicate_slices_is_boolean?

        response
        Superset::Dashboard::Get.new(id).perform  # return the full new dashboard object
      end

      def params
        {
          "css" => "{}",
          "dashboard_title" => "#{source_dashboard.title} (COPY)",
          "duplicate_slices" => duplicate_slices,
          "json_metadata" => source_dashboard_json_metadata_with_positions.to_json,
        }
      end

      def response
        @response ||= client.post(route, params)
      end

      def id
        response["result"]["id"]
      end

      private

      def route
        "dashboard/#{source_dashboard_id}/copy/"
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
          dash = Get.new(source_dashboard_id)
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
