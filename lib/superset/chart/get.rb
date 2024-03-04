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

      def result
        [ super ]
      end

      private

      def route
        "chart/#{id}"
      end

      def list_attributes
        %w(id slice_name owners dashboards)
      end

    end
  end
end
