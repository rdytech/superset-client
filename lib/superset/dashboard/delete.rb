# frozen_string_literal: true

module Superset
  module Dashboard
    class Delete < Superset::Request

      attr_reader :dashboard_id, :confirm_zero_charts

      def initialize(dashboard_id: , confirm_zero_charts: true)
        @dashboard_id = dashboard_id
        @confirm_zero_charts = confirm_zero_charts
      end

      def perform
        raise InvalidParameterError, "dashboard_id integer is required" unless dashboard_id.present? && dashboard_id.is_a?(Integer)

        confirm_zero_charts_on_dashboard if confirm_zero_charts

        logger.info("Deleting dashboard with id: #{dashboard_id}")
        response
      end

      def response
        @response ||= client.delete(route)
      end

      private

      def confirm_zero_charts_on_dashboard
        raise "Error: Dashboard includes #{dashboard_charts.count} charts. Please delete all charts before deleting the dashboard or override and set confirm_zero_charts: false" if dashboard_charts.count.positive?
      end

      def dashboard_charts
        @dashboard_charts ||= Superset::Dashboard::Charts::List.new(dashboard_id).rows
      end

      def route
        "dashboard/#{dashboard_id}"
      end
    end
  end
end
