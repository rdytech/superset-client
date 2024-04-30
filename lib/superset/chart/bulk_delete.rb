# frozen_string_literal: true
# TODO: the gui delete has a confirmation step, this does not.  Potentially add a confirm_delete parameter to the constructor
# that would ensure that all charts belong to an expected dashboard before deleting.  ( not sure if this is a good idea )


module Superset
  module Chart
    class BulkDelete < Superset::Request
      attr_reader :chart_ids

      def initialize(chart_ids: [])
        @chart_ids = chart_ids
      end

      def perform
        raise InvalidParameterError, "chart_ids array of integers expected" unless chart_ids.is_a?(Array)
        raise InvalidParameterError, "chart_ids array must contin Integer only values" unless chart_ids.all? { |item| item.is_a?(Integer) }

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
