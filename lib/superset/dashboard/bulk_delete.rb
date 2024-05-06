# frozen_string_literal: true

# TODO: the gui delete has a confirmation step, this API call does not.
# Potentially we could add a confirm_delete parameter to the constructor that would ensure that all dashboards either
#   1 have an expected set of charts or filters before deleting
#   2 or do not have any charts or filters linked to them
#  ( not sure if this needed at this point )

# NOTE: deletes the Dashboard Only. Use Dashboard::BulkDeleteCascade to delete all related objects
module Superset
  module Dashboard
    class BulkDelete < Superset::Request
      attr_reader :dashboard_ids

      def initialize(dashboard_ids: [])
        @dashboard_ids = dashboard_ids
      end

      def perform
        raise InvalidParameterError, "dashboard_ids array of integers expected" unless dashboard_ids.is_a?(Array)
        raise InvalidParameterError, "dashboard_ids array must contain Integer only values" unless dashboard_ids.all? { |item| item.is_a?(Integer) }

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
