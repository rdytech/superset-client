# Assumptions
# - The source dashboard is in the same Superset instance as the target database and target schema
# - All charts datasets on the source dashboard are pointing to the same database schema


module Superset
  module Services
    class DuplicateDashboard < Superset::Request

      attr_reader :source_dashboard_id, :target_schema, :target_database_id

      def initialize(source_dashboard_id:, target_schema:, target_database_id: )
        @source_dashboard_id = source_dashboard_id
        @target_schema = target_schema
        @target_database_id = target_database_id
      end

      def perform
        validate_params

        # create a new_dashboard by copying the source_dashboard using with 'duplicate_slices: true' to get a new set of charts.
        new_dashboard

        # Pull the Datasets for all charts on the source dashboard  
        # currently the new_dashboard charts(slices) all point to these same datasets from the orig source dashboard 
        source_dashboard_datasets

        # Duplicate these Datasets to the new target schema and target database
        duplicate_source_dashboard_datasets

        # Update the Charts on the New Dashboard with the New Datasets
        update_charts_with_new_datasets

      end

      # private

      def dataset_duplication_tracker
        @dataset_duplication_tracker ||= []
      end

      def update_charts_with_new_datasets

        # get all chart ids for the new dashboard
        chart_ids_list = Superset::Dashboard::Charts::List.new(new_dashboard.id).chart_ids

        # for each chart, update the charts current dataset_id with the new dataset_id
        chart_ids_list.each do |chart_id|

          # get the CURRENT dataset_id for the chart
          current_chart_dataset_id = Superset::Chart::Get.new(chart_id).datasource_id

          # find the new dataset_id for the chart, based on the current_chart_dataset_id
          new_dataset_id = dataset_duplication_tracker.find { |dataset| dataset[:source_dataset_id] == current_chart_dataset_id }&.fetch(:new_dataset_id, nil)

          # update the chart to target the new dataset_id
          chart_update = Superset::Chart::UpdateDataset.new(chart_id: chart_id, target_dataset_id: new_dataset_id)
          chart_update.response
        end
      end

      

      def duplicate_source_dashboard_datasets
        source_dashboard_datasets.each do |dataset|
          # duplicate the dataset
          new_dataset = Superset::Dataset::Duplicate.new(source_dataset_id: dataset[:id], new_dataset_name: "#{dataset[:datasource_name]} #{target_schema} DUPLICATION")
          new_dataset_id = new_dataset.perform
          dataset_duplication_tracker <<  { source_dataset_id: dataset[:id], new_dataset_id: new_dataset_id }

          # update the new dataset with the target schema and target database
          update_dataset = Superset::Dataset::UpdateSchema.new(source_dataset_id: new_dataset_id, target_database_id: target_database_id, target_schema: target_schema)
          update_dataset.response
        end
      end

      def new_dashboard
        @new_dashboard ||= Superset::Dashboard::Copy.new(
            source_dashboard_id: source_dashboard_id,
            duplicate_slices:    true
          ).perform
      end

      # retrieve the datasets for the that we will duplicate
      def source_dashboard_datasets
        @source_dashboard_datasets ||= Superset::Dashboard::Datasets::List.new(source_dashboard_id).datasets_details
      end

      def validate_params
        # params validations
        raise "Error: source_dashboard_id integer is required" unless source_dashboard_id.present? && source_dashboard_id.is_a?(Integer)
        raise "Error: target_schema string is required" unless target_schema.present? && target_schema.is_a?(String)
        raise "Error: target_database_id integer is required" unless target_database_id.present? && target_database_id.is_a?(Integer)

        # dashboard validations
        # Validation of source dashboard existance will occur inside the new_dashboard call

        # schema validations
        raise "Error: Schema #{target_schema} does not exist in target database: #{target_database_id}" unless target_database_available_schemas.include?(target_schema)
        raise "Error: The souce_dashboard_id #{source_dashboard_id} datasets point to more than one schema. Schema list is #{source_dashboard_schemas.join(',')}" if source_dashboard_has_more_than_one_schema?
      end

      def target_database_available_schemas
        Superset::Database::GetSchemas.call(target_database_id)
      end

      def source_dashboard_has_more_than_one_schema?
        source_dashboard_schemas.count > 1
      end

      def source_dashboard_schemas
        source_dashboard_datasets.map { |dataset| dataset[:schema] }.uniq
      end
    end
  end
end