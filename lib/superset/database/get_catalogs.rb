module Superset
  module Database
    class GetCatalogs < Superset::Request

      attr_reader :id, :include_system_catalogs

      def initialize(id, include_system_catalogs: false)
        @id = id
        @include_system_catalogs = include_system_catalogs
      end

      def self.call(id)
        self.new(id).catalogs
      end
 
      def catalogs
        return result if include_system_catalogs

        remove_system_catalogs
      end

      private

      def route
        "database/#{id}/catalogs/"
      end

      # exclude system catalog values for certain databases that support them
      def remove_system_catalogs
        result - postgres_system_catalogs
      end

      def postgres_system_catalogs
        %w(postgres rdsadmin template1 template0)
      end
    end
  end
end
