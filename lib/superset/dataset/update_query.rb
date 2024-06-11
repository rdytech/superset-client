module Superset
  module Dataset
    class UpdateQuery < Superset::Request

      attr_reader :new_query, :dataset_id

      def initialize(dataset_id: ,new_query: )
        @new_query = new_query
        @dataset_id = dataset_id
      end

      def perform
        validate_proposed_changes

        response
      end

      def response
        @response ||= client.put(route, params)
      end

      def params
        { "sql": new_query }
      end

      # check if the sql query embedds the schema name, if so it can not be duplicated cleanly
      def sql_query_includes_hard_coded_schema?
        new_query.include?("#{source_dataset['schema']}.")
      end

      def source_dataset
        # will raise an error if the dataset does not exist
        @source_dataset ||= begin
          dataset = Get.new(dataset_id)
          dataset.result
        end
      end

      private

      def validate_proposed_changes
        logger.info "    Validating Dataset ID: #{dataset_id} query update to '#{new_query}'"
        raise "Error: dataset_id integer is required"  unless dataset_id.present? && dataset_id.is_a?(Integer)
        raise "Error: new_query string is required"       unless new_query.present? && new_query.is_a?(String)

        # does the sql query hard code the current schema name?
        raise "Error: >>WARNING<< The Dataset ID #{dataset_id} SQL query is hard coded with the schema value and can not be duplicated cleanly. " +
              "Remove all direct embedded schema calls from the Dataset SQL query before continuing." if sql_query_includes_hard_coded_schema?
      end

      def route
        "dataset/#{dataset_id}"
      end
    end
  end
end
