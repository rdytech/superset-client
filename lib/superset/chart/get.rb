module Superset
  module Chart
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

      def datasource_id
        if result['query_context'].present? && JSON.parse(result['query_context'])['datasource'].present?
          JSON.parse(result['query_context'])['datasource']['id']
        elsif result['params'].present? && JSON.parse(result['params'])['datasource'].present?
          JSON.parse(result['params'])['datasource'].match(/^\d+/)[0].to_i
        end
      end

      def owner_ids
        result['owners'].map{|o| o['id']}
      end

      def params
        JSON.parse(result['params']) if result['params'].present?
      end

      def query_context
        JSON.parse(result['query_context']) if result['query_context'].present?
      end

      private

      def route
        "chart/#{id}"
      end

      def list_attributes
        %w(id slice_name owners)
      end

    end
  end
end
