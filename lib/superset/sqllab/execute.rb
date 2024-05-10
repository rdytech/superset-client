module Superset
  module Sqllab
    class Execute < Superset::Request
      class InvalidParameterError < StandardError; end

      attr_reader :database_id, :query, :schema

      def initialize(database_id: , query: , schema: 'public')
        @database_id = database_id
        @query = query
        @schema = schema
      end

      def perform
        validate_constructor_args
        response
        data
      end

      def response
        @response ||= client.post(route, query_params)
      end

      def data
        response["data"]
      end

      private

      def route
        "sqllab/execute/"
      end

      def query_params
        {
          database_id: database_id,
          sql:         query,
          schema:      schema,
          queryLimit:  1000,
          runAsync: false,
        }
      end

      def validate_constructor_args
        raise InvalidParameterError, "database_id integer is required" unless database_id.present? && database_id.is_a?(Integer)
        raise InvalidParameterError, "query string is required" unless query.present? && query.is_a?(String)
        raise InvalidParameterError, "schema must be a String type" unless schema.is_a?(String)
      end
    end
  end
end