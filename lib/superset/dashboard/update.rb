
# TODO: some work to happen around TAGS still .. ie 'template' tag would indicate it tested and available to be copied.
# TODO: also need to ensoure that the embedded details are not duplicated across to the new dashboard

module Superset
  module Dashboard
    class Update < Superset::Request

      attr_reader :target_dashboard_id, :duplicate_slices

      def initialize(target_dashboard_id:, params:)
        @target_dashboard_id = target_dashboard_id
      end

      def perform
        raise "Error: target_dashboard_id integer is required" unless target_dashboard_id.present? && target_dashboard_id.is_a?(Integer)

        response
        self
      end

      def response
        @response ||= client.put(route, params)
      end

      def id
        response["result"]["id"]
      end

      private

      def route
        "dashboard/#{target_dashboard_id}/update/"
      end
    end
  end
end
