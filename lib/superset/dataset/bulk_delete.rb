# frozen_string_literal: true

# TODO: the gui delete has a confirmation step, this API call does not.
# Potentially we could add a confirm_delete parameter to the constructor that would ensure that all datasets either
#   1 belong to only an expected charts or filters before deleting
#   2 or do not belong to any charts or filters
#  ( not sure if this needed at this point )

module Superset
  module Dataset
    class BulkDelete < Superset::Request
      attr_reader :dataset_ids

      def initialize(dataset_ids: [])
        @dataset_ids = dataset_ids
      end

      def perform
        raise InvalidParameterError, "dataset_ids array of integers expected" unless dataset_ids.is_a?(Array)
        raise InvalidParameterError, "dataset_ids array must contin Integer only values" unless dataset_ids.all? { |item| item.is_a?(Integer) }

        logger.info("Attempting to delete datasets with id: #{dataset_ids.join(', ')}")
        response
      end

      def response
        @response ||= client.delete(route, params)
      end

      private

      def params
        { q: "!(#{dataset_ids.join(',')})" }
      end

      def route
        "dataset/"
      end
    end
  end
end
