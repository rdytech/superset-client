module Superset
  module Dataset
    class Get < Superset::Request

      attr_reader :id

      def initialize(id)
        @id = id
      end

      def self.call(id)
        self.new(id).list
      end

      def perform
        response
        self
      end

      def rows
        [ [title, schema, database_name, database_id] ]
      end

      def schema
        result['schema']
      end

      def title
        result['name']
      end

      def database_name
        result['database']['database_name']
      end

      def database_id
        result['database']['id']
      end

      def sql
        ['sql']
      end

      private

      def route
        "dataset/#{id}"
      end

      def display_headers
        %w[title schema database_name, database_id]
      end
    end
  end
end
