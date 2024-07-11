module Superset
  module Dataset
    class WarmUpCache < Superset::Request

      attr_reader :dashboard_id
      
      def initialize(dashboard_id:)
        @dashboard_id = dashboard_id
      end

      def perform
        validate_dashboard_id
        response
      end

      def response
        dataset_details = fetch_dataset_details(dashboard_id)
        dataset_details.each do |dataset|
          begin
            logger.info("Hitting #{route} for warming up the cache for the dashboard #{dashboard_id.to_s} and for the dataset #{dataset["datasource_name"]}")
            api_response(dataset["datasource_name"], dataset["name"])
          rescue => e
            Rollbar.error("Warm up cache failed for the dashboard #{dashboard_id.to_s} and for the dataset #{dataset["datasource_name"]} - #{e.message}")
          end 
        end
      end

      def api_response(dataset_name, db_name)
        client.put(route, params(dashboard_id, dataset_name, db_name))
      end

      def params(dashboard_id, dataset_name, db_name)
        {
          "dashboard_id" => dashboard_id,
          "table_name" => dataset_name,
          "db_name" => db_name
        }
      end

      private
      
      def validate_dashboard_id
        raise InvalidParameterError, "dashboard_id must be present and must be an integer" unless dashboard_id.present? && dashboard_id.is_a?(Integer)
      end

      def fetch_dataset_details(dashboard_id)
        Superset::Dashboard::Datasets::List.new(dashboard_id).datasets_details.map { |dataset| dataset['database'].slice('name').merge(dataset.slice('datasource_name'))}
      end

      def route
        "dataset/warm_up_cache"
      end

      def logger
        @logger ||= Superset::Logger.new
      end
    end
  end
end
