module Superset
  module Database
    class GetSchemas < Superset::Request

      alias :schemas :result
      alias :list :result

      attr_reader :id

      def initialize(id)
        @id = id
      end

      def self.call(id)
        self.new(id).schemas
      end
 
      private

      def route
        "database/#{id}/schemas/"
      end
    end
  end
end
