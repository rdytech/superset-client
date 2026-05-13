module Superset
  module Tag
    class GetObjects < Superset::Request

      attr_reader :id

      def initialize(id)
        @id = id
        super()
      end

      def self.call(id)
        self.new(id).list
      end

      private

      def route
        "tag/get_objects/#{id}"
      end

      def list_attributes
        ['id', 'name', 'type', 'url']
      end
    end
  end
end
