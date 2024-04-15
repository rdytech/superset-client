# frozen_string_literal: true

module Superset
  module Tag
    class AddToObject < Superset::Request

      attr_reader :object_type, :object_id, :tags

      def initialize(object_type:, object_id:, tags: [])
        @object_type = object_type
        @object_id = object_id
        @tags = tags
      end

      def perform
        raise "Error: object_type integer is required" unless object_type.present? && object_type.is_a?(Integer)
        raise "Error: object_id integer is required" unless object_id.present? && object_id.is_a?(Integer)
        raise "Error: tags array is required" unless tags.present? && tags.is_a?(Array)
        raise "Error: tags array must contin string only values" unless tags.all? { |item| item.is_a?(String) }

        response  # NOTE API response for success is {} .. not particularly informative
      end

      def response
        @response ||= client.post(route, params)
      end

      def params
        {
          "properties": { "tags": tags }
        }
      end

      private

      def route
        "dashboard/#{object_type}"
        "tag/#{object_type}/#{object_id}/"
      end
    end
  end
end
