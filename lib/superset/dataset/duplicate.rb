# The API demands that the new_dataset_name be uniq within the schema it points to.
# same behaviour as in the GUI

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

        logger.info("  Start Duplicate Source Dataset Id: #{source_dataset_id} to New Dataset Name: #{new_dataset_name}")
        
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
        if response["id"].present?
          logger.info("  Finish Duplicate Dataset. New Dataset Id: #{response['id']}")
          response["id"]
        else
          logger.error("Error: Unable to duplicate dataset: #{response}")
          raise "Error: Unable to duplicate dataset: #{response}"
        end
      end

      def route
        "dataset/duplicate"
      end
    end
  end
end
