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
        [to_h.values]
      end

      def to_h
        list_attributes.to_h { |a| [a, send(a)] }
      end

      def schema
        result['schema']
      end

      def title
        result['table_name']
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

      def list_attributes
        [:title, :schema, :database_name, :database_id]
      end
    end
  end
end
