module Superset
  module Dataset
    class WarmUpCache < Superset::Request

      attr_reader :dashboard_id, :table_name, :db_name
      
      def initialize(dashboard_id:, table_name:, db_name:)
        @dashboard_id = dashboard_id
        @table_name = table_name
        @db_name = db_name
      end

      def perform
        response
      end

      def response
        logger.info("Hitting #{route} for warming up the cache for the dashboard #{dashboard_id.to_s} and for the dataset #{table_name}")
        client.put(route, params(dashboard_id, table_name, db_name))
      end

      def params(dashboard_id, table_name, db_name)
        {
          "dashboard_id" => dashboard_id,
          "table_name" => table_name,
          "db_name" => db_name
        }
      end

      private

      def route
        "dataset/warm_up_cache"
      end

      def logger
        @logger ||= Superset::Logger.new
      end
    end
  end
end
