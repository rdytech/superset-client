module Superset
  module Dashboard
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

      def title
        "#{result['dashboard_title']}"
      end

      def json_metadata
        JSON.parse(result['json_metadata'])
      end

      def positions
        JSON.parse(result['position_json'])
      end

      def url
        "#{superset_host}#{result['url']}"
      end

      private

      def route
        "dashboard/#{id}"
      end

      def rows
        result['charts'].map {|c| [c]}
      end

      def headings
        ['Charts']
      end
    end
  end
end
