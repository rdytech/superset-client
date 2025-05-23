# frozen_string_literal: true

# Description: This endpoint has the same functionality as 'Sync Columns from Source' button in the Superset UI on a dataset.
# Executes the dataset against the source to confirm the query runs and then sync and cache dataset columns.
# NOTICE: only owners of the dataset can refresh it
#
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
