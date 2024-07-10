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
            client.put(route, params(dashboard_id, dataset["datasource_name"], dataset["name"]))
          rescue => e
            Rollbar.error(e.message)
          end 
        end
      end

      def validate_dashboard_id
        raise InvalidParameterError, "dashboard_id must be present and must be an integer" unless dashboard_id.present? && dashboard_id.is_a?(Integer)
      end

      def params(dashboard_id, dataset_name, db_name)
        {
          "dashboard_id" => dashboard_id,
          "table_name" => dataset_name,
          "db_name" => db_name
        }
      end

      def fetch_dataset_details(dashboard_id)
        Superset::Dashboard::Datasets::List.new(dashboard_id).datasets_details.map { |dataset| dataset['database'].slice('name').merge(dataset.slice('datasource_name'))}
      end

      private

      def route
        "dataset/warm_up_cache"
      end
    end
  end
end
