# frozen_string_literal: true
# TODO: the gui delete has a confirmation step, this does not.  Potentially add a confirm_delete parameter to the constructor
# that would ensure that no charts belong to a dashboard before deleting

module Superset
  module Dashboard
    class BulkDelete < Superset::Request
      attr_reader :dashboard_ids

      def initialize(dashboard_ids: [])
        @dashboard_ids = dashboard_ids
      end

      def perform
        raise InvalidParameterError, "dashboard_ids array of integers expected" unless dashboard_ids.is_a?(Array)
        raise InvalidParameterError, "dashboard_ids array must contin Integer only values" unless dashboard_ids.all? { |item| item.is_a?(Integer) }

        logger.info("Attempting to delete dashboards with id: #{dashboard_ids.join(', ')}")
        response
      end

      def response
        @response ||= client.delete(route, params)
      end

      private

      def params
        { q: "!(#{dashboard_ids.join(',')})" }
      end

      def route
        "dashboard/"
      end
    end
  end
end
