# frozen_string_literal: true

# Description: Same functionality as 'Sync Columns from Source' button in the Superset UI on a dataset.
# Executes the dataset against the source to confirm query run and sync and cache dataset columns for charting.
# Usage: Superset::Dataset::Refresh.call(id)

module Superset
  module Dataset
    class Refresh < Superset::Request

      attr_reader :id

      def initialize(id)
        @id = id
      end

      def self.call(id)
        self.new(id).perform
      end

      def perform
        response
      end

      def response
        @response ||= client.put(route)
      end

      private

      def route
        "dataset/#{id}/refresh"
      end
    end
  end
end
