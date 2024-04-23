
# TODO: some work to happen around TAGS still .. ie 'template' tag would indicate it tested and available to be copied.
# TODO: also need to ensoure that the embedded details are not duplicated across to the new dashboard

module Superset
  module Dashboard
    class Copy < Superset::Request

      attr_reader :source_dashboard_id, :duplicate_slices, :clear_shared_label_colors

      def initialize(source_dashboard_id: , duplicate_slices: false, clear_shared_label_colors: false)
        @source_dashboard_id = source_dashboard_id
        @duplicate_slices = duplicate_slices # boolean indicates whether to duplicate charts OR keep the new dashboard pointing to the same charts as the original
        @clear_shared_label_colors = clear_shared_label_colors
      end

      def perform
        raise "Error: source_dashboard_id integer is required" unless source_dashboard_id.present? && source_dashboard_id.is_a?(Integer)
        raise "Error: duplicate_slices must be a boolean" unless duplicate_slices_is_boolean?

        adjust_json_metadata
        response
        Superset::Dashboard::Get.new(id).perform  # return the full new dashboard object
      end

      def params
        {
          "css" => "{}",
          "dashboard_title" => "#{source_dashboard.title}",
          "duplicate_slices" => duplicate_slices,
          "json_metadata" => new_dashboard_json_metadata.to_json,
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

      def adjust_json_metadata
        # when copying a DB via the API, chart positions need to be nested under json_metadata according to the GUI copy function  (as per dev tools investigation in browser)
        new_dashboard_json_metadata.merge!( "positions" => source_dashboard.positions )

        if clear_shared_label_colors
          # if coping a dashboard to a new db schema .. shared label colors will not be relevant/match as they are specific to the previous schemas dataset values
          new_dashboard_json_metadata.merge!( "shared_label_colors" => {} )
        end
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

      def new_dashboard_json_metadata
        @new_dashboard_json_metadata ||= source_dashboard.json_metadata
      end

      def duplicate_slices_is_boolean?
        [true, false].include?(duplicate_slices)
      end
    end
  end
end
