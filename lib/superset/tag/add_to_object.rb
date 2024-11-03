# frozen_string_literal: true

# Add tags to an object
# for object type options see ObjectType.to_a
#
# Usage:
# Superset::Tag::AddToObject.new(object_type_id: ObjectType::DASHBOARD, object_id: new_dashboard.id, tags: tags).perform

module Superset
  module Tag
    class AddToObject < Superset::Request

      attr_reader :object_type_id, :object_id, :tags

      def initialize(object_type_id:, object_id:, tags: [])
        @object_type_id = object_type_id
        @object_id = object_id
        @tags = tags
      end

      def perform
        validate_constructor_args

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

      def validate_constructor_args
        raise InvalidParameterError, "object_type_id integer is required" unless object_type_id.present? && object_type_id.is_a?(Integer)
        raise InvalidParameterError, "object_type_id is not a known value" unless ObjectType.list.include?(object_type_id)
        raise InvalidParameterError, "object_id integer is required" unless object_id.present? && object_id.is_a?(Integer)
        raise InvalidParameterError, "tags array is required" unless tags.present? && tags.is_a?(Array)
        raise InvalidParameterError, "tags array must contain string only values" unless tags.all? { |item| item.is_a?(String) }
      end

      private

      def route
        "tag/#{object_type_id}/#{object_id}/"
      end
    end
  end
end
