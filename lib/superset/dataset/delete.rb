# frozen_string_literal: true

module Superset
  module Dataset
    class Delete < Superset::Request
      attr_reader :dataset_id

      def initialize(dataset_id: )
        @dataset_id = dataset_id
      end

      def perform
        raise InvalidParameterError, "dataset_id integer is required" unless dataset_id.present? && dataset_id.is_a?(Integer)

        logger.info("Deleting dataset with id: #{dataset_id}")
        response
      end

      def response
        @response ||= client.delete(route)
      end

      private

      def route
        "dataset/#{dataset_id}"
      end
    end
  end
end
