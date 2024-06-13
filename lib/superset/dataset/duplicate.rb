# The API demands that the new_dataset_name be uniq within the schema it points to.
# same behaviour as in the GUI

module Superset
  module Dataset
    class Duplicate < Superset::Request

      attr_reader :source_dataset_id, :new_dataset_name

      def initialize(source_dataset_id: , new_dataset_name: )
        @source_dataset_id = source_dataset_id
        @new_dataset_name = new_dataset_name
      end

      def perform
        raise "Error: source_dataset_id integer is required" unless source_dataset_id.present? && source_dataset_id.is_a?(Integer)
        raise "Error: new_dataset_name string is required" unless new_dataset_name.present? && new_dataset_name.is_a?(String)
        raise "Error: new_dataset_name already in use in this schema: #{new_dataset_name}. Suggest you add (COPY) as a suffix to the name" if new_dataset_name_already_in_use?

        logger.info("Duplicating Source Dataset #{source_dataset.title} with id #{source_dataset_id}")

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

      def source_dataset
        @source_dataset ||= Dataset::Get.new(source_dataset_id).perform
      end

      # The API demands that the new_dataset_name be uniq within the schema it points to.
      def new_dataset_name_already_in_use?
        Dataset::List.new(title_equals: new_dataset_name, schema_equals: source_dataset.schema).result.any?
      end

      def new_dataset_id
        if response["id"].present?
          logger.info("    Finished. Duplicate Dataset Name #{new_dataset_name} with id #{response['id']}")
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
