# frozen_string_literal: true
# TODO: the gui delete has a confirmation step, this API call does not.
# Potentially we could add a confirm_delete parameter to the constructor that would ensure that all charts either
#   1 belong to only an expected dashboard before deleting
#   2 or do not belong to any dashboards
#  ( not sure if this needed at this point )

module Superset
  module Chart
    class BulkDelete < Superset::Request
      attr_reader :chart_ids

      def initialize(chart_ids: [])
        @chart_ids = chart_ids
      end

      def perform
        raise InvalidParameterError, "chart_ids array of integers expected" unless chart_ids.is_a?(Array)
        raise InvalidParameterError, "chart_ids array must contain Integer only values" unless chart_ids.all? { |item| item.is_a?(Integer) }

        logger.info("Attempting to delete charts with id: #{chart_ids.join(', ')}")
        response
      end

      def response
        @response ||= client.delete(route, params)
      end

      private

      def params
        { q: "!(#{chart_ids.join(',')})" }
      end

      def route
        "chart/"
      end
    end
  end
end
