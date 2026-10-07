# frozen_string_literal: true

module Superset
  module Chart
    class Delete < Superset::Request
      attr_reader :chart_id

      def initialize(chart_id: )
        @chart_id = chart_id
      end

      def perform
        raise InvalidParameterError, "chart_id integer is required" unless chart_id.present? && chart_id.is_a?(Integer)

        logger.info("Deleting chart with id: #{chart_id}")
        response
      end

      def response
        @response ||= client.delete(route)
      end

      private

      def route
        "chart/#{chart_id}"
      end
    end
  end
end
