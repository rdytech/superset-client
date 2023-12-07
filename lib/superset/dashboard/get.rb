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

      def title
        "#{id}: #{result['dashboard_title']}"
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
