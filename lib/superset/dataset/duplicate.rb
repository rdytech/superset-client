module Superset
  module Dataset
    class Duplicate < Superset::Request

      attr_reader :source_dataset_id, :new_dataset_name

      def initialize(source_dataset_id: :source_dataset_id, new_dataset_name: :new_dataset_name)
        @source_dataset_id = source_dataset_id
        @new_dataset_name = new_dataset_name
      end

      def perform
        raise "Error: source_dataset_id integer is required" unless source_dataset_id.present? && source_dataset_id.is_a?(Integer)
        raise "Error: new_dataset_name string is required" unless new_dataset_name.present? && new_dataset_name.is_a?(String)
        raise "Error: new_dataset_name already in use" if new_dataset_name_already_in_use?
        
        new_dataset_id
      end

      def response
        @response ||= client.post(route, params)
      end

      def params
        {
          "base_model_id" => source_dataset_id,
          "table_name" => new_dataset_name
        }
      end

      private
      
      def new_dataset_name_already_in_use?
        existing_datasets = List.new(title_equals: new_dataset_name)
        existing_datasets.result.any?
      end

      def new_dataset_id
        response["id"]
      end

      def route
        "dataset/duplicate"
      end
    end
  end
end
