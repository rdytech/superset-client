# frozen_string_literal: true

# Delete tags from an object
# for object type options see ObjectType.to_a
#
# Usage:
# Superset::Tag::DeleteFromObject.new(object_type_id: ObjectType::DASHBOARD, object_id: 101, tag: 'test-tag').perform

module Superset
  module Tag
    class DeleteFromObject < Superset::Request

      attr_reader :object_type_id, :object_id, :tag

      def initialize(object_type_id:, object_id:, tag:)
        @object_type_id = object_type_id
        @object_id = object_id
        @tag = tag
      end

      def perform
        validate_constructor_args

        response
      end

      def response
        @response ||= client.delete(route)
      end

      def validate_constructor_args
        raise InvalidParameterError, "object_type_id integer is required" unless object_type_id.present? && object_type_id.is_a?(Integer)
        raise InvalidParameterError, "object_type_id is not a known value" unless ObjectType.list.include?(object_type_id)
        raise InvalidParameterError, "object_id integer is required" unless object_id.present? && object_id.is_a?(Integer)
        raise InvalidParameterError, "tag string is required" unless tag.present? && tag.is_a?(String)
      end

      private

      def route
        "tag/#{object_type_id}/#{object_id}/#{tag}/"
      end
    end
  end
end
