# Updates a chart in Superset with the given params
#
# Usage:
# params = { owners: [ 58, 3 ] }
# Superset::Chart::Put.new(chart_id: 3998, params: params ).perform

module Superset
  module Chart
    class Put < Superset::Request

      attr_reader :chart_id, :params

      def initialize(chart_id: , params:)
        @chart_id = chart_id
        @params = params
      end

      def perform
        validate_proposed_changes
        response
      end

      def response
        @response ||= client.put(route, params)
      end

      private

      def validate_proposed_changes
        raise "Error: chart_id integer is required" unless chart_id.present? && chart_id.is_a?(Integer)
        raise "Error: params hash is required" unless params.present? && params.is_a?(Hash)
      end

      def route
        "chart/#{chart_id}"
      end
    end
  end
end
