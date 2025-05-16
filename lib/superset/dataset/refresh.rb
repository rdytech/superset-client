module Superset
  module Dataset
    class Refresh < Superset::Request

      attr_reader :id

      def initialize(id)
        @id = id
      end

      def self.call(id)
        self.new(id).perform
      end

      def perform
        response
      end

      def response
        @response ||= client.put(route)
      end

      private

      def route
        "dataset/#{id}/refresh"
      end
    end
  end
end
