module Superset
  module Tag
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

      def list_attributes
        ['id', 'name', 'type', 'description']
      end

      def route
        "tag/#{id}"
      end
    end
  end
end
