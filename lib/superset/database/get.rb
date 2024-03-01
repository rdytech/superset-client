module Superset
  module Database
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
        "database/#{id}"
      end

      def list_attributes
        %w(id database_name backend driver expose_in_sqllab cache_timeout allow_file_upload)
      end
    end
  end
end
