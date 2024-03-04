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

      def rows
        [ [title, schema, database_name, database_id] ]
      end

      private

      def route
        "dataset/#{id}"
      end

      def display_headers
        %w[title schema database_name, database_id]
      end
  

      def database_name
        result['database']['database_name']
      end

      def database_id
        result['database']['id']
      end

      def title
        result['name']
      end

      def schema
        result['schema']
      end

      def sql
        ['sql']
      end
    end
  end
end
