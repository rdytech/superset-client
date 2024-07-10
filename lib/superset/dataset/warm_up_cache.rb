module Superset
  module Dataset
    class WarmUpCache < Superset::Request
      attr_reader :db_name

      def initialize(db_name:)
        @db_name = db_name
      end

      def perform
        dashboard_ids = fetch_dashboard_ids
        dashboard_ids.each do |dashboard_id|
          dataset_names = fetch_dataset_names(dashboard_id)
          dataset_names.each do |dataset_name|
            begin
              client.put(route, params(dataset_name, dashboard_id))
            rescue => e
              Rollbar.error(e.message)
            end 
          end
        end    
      end

      def params(dataset_name, dashboard_id)
        {
          "dashboard_id" => dashboard_id,
          "table_name" => dataset_name,
          "db_name" => db_name
        }
      end

      def fetch_dashboard_ids
        Superset::Dashboard::List.new(tags_equal: ['embedded', 'product:jobready']).ids
      end

      def fetch_dataset_names(dashboard_id)
        Superset::Dashboard::Datasets::List.new(dashboard_id).dataset_names
      end

      private

      def route
        "dataset/warm_up_cache"
      end
    end
  end
end
