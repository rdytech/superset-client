
# frozen_string_literal: true

module Superset
  module Dashboard
    class Put < Superset::Request

      attr_reader :target_dashboard_id, :params

      def initialize(target_dashboard_id:, params:)
        @target_dashboard_id = target_dashboard_id
        @params = params
      end

      def perform
        raise "Error: target_dashboard_id integer is required" unless target_dashboard_id.present? && target_dashboard_id.is_a?(Integer)
        raise "Error: params hash is required" unless params.present? && params.is_a?(Hash)

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
        "dashboard/#{target_dashboard_id}"
      end
    end
  end
end
