# Assumptions
# - The source dashboard is in the same Superset instance as the target database and target schema
# - All charts datasets on the source dashboard are pointing to the same database schema


module Superset
  module Services
    class DuplicateDashboard < Superset::Request

      DUPLICATED_DATASET_SUFFIX = ' (COPY)'

      attr_reader :source_dashboard_id, :target_schema, :target_database_id, :embedded_domain

      def initialize(source_dashboard_id:, target_schema:, target_database_id: , embedded_domain: '')
        @source_dashboard_id = source_dashboard_id
        @target_schema = target_schema
        @target_database_id = target_database_id
        @embedded_domain = embedded_domain
      end

      def perform
        validate_params

        # Pull the Datasets for all charts on the source dashboard
        source_dashboard_datasets

        # create a new_dashboard by copying the source_dashboard using with 'duplicate_slices: true' to get a new set of charts.
        # The new_dashboard will have a copy of charts from the source_dashboard, but with the same datasets as the source_dashboard
        new_dashboard

        # Duplicate these Datasets to the new target schema and target database
        duplicate_source_dashboard_datasets

        # Update the Charts on the New Dashboard with the New Datasets
        update_charts_with_new_datasets

        created_embedded_config

        end_log_message

        # return the new dashboard id and url
        { new_dashboard_id: new_dashboard.id, new_dashboard_url: new_dashboard.url }

      rescue => e
        logger.error("#{e.message}")
        raise e
      end

      #private

      def created_embedded_config
        return unless embedded_domain.present?

        result = Dashboard::Embedded::Put.new(dashboard_id: new_dashboard.id, embedded_domain: embedded_domain).result
        logger.info "  Embedded Domain Added to New Dashboard #{new_dashboard.id}:"
        logger.info "  Embedded Domain allowed_domains: #{result['allowed_domains']}"
        logger.info "  Embedded Domain uuid: #{result['uuid']}"
      end

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
          Superset::Chart::UpdateDataset.new(chart_id: chart_id, target_dataset_id: new_dataset_id).response
        end
      end

      def duplicate_source_dashboard_datasets
        source_dashboard_datasets.each do |dataset|
          # duplicate the dataset
          new_dataset_id = Superset::Dataset::Duplicate.new(source_dataset_id: dataset[:id], new_dataset_name: "#{dataset[:datasource_name]}#{DUPLICATED_DATASET_SUFFIX}").perform

          # keep track of the previous dataset and the matching new dataset_id
          dataset_duplication_tracker <<  { source_dataset_id: dataset[:id], new_dataset_id: new_dataset_id }

          # update the new dataset with the target schema and target database
          Superset::Dataset::UpdateSchema.new(source_dataset_id: new_dataset_id, target_database_id: target_database_id, target_schema: target_schema).response
        end
      end

      def new_dashboard
        @new_dashboard ||= begin
          copy = Superset::Dashboard::Copy.new(
            source_dashboard_id: source_dashboard_id,
            duplicate_slices:    true
          ).perform
          logger.info("  Copy Dashboard/Charts Completed - New Dashboard ID: #{copy.id}")
          copy
        end
      rescue => e
        raise "Dashboard::Copy error: #{e.message}"
      end

      # retrieve the datasets for the that we will duplicate
      def source_dashboard_datasets
        @source_dashboard_datasets ||= Superset::Dashboard::Datasets::List.new(source_dashboard_id).datasets_details
      rescue => e
        raise "Unable to retrieve datasets for source dashboard #{source_dashboard_id}: #{e.message}"
      end

      def validate_params
        start_log_msg
        # params validations
        raise  InvalidParameterError, "source_dashboard_id integer is required" unless source_dashboard_id.present? && source_dashboard_id.is_a?(Integer)
        raise  InvalidParameterError, "target_schema string is required" unless target_schema.present? && target_schema.is_a?(String)
        raise  InvalidParameterError, "target_database_id integer is required" unless target_database_id.present? && target_database_id.is_a?(Integer)

        # dashboard validations
        # Validation of source dashboard existance will occur inside the new_dashboard call

        # schema validations
        raise ValidationError, "Schema #{target_schema} does not exist in target database: #{target_database_id}" unless target_database_available_schemas.include?(target_schema)
        raise ValidationError, "The source_dashboard_id #{source_dashboard_id} datasets are required to point to one schema only. Actual schema list is #{source_dashboard_schemas.join(',')}" if source_dashboard_has_more_than_one_schema?
 
        # new dataset validations
        raise ValidationError, "DATASET NAME CONFLICT: The Target Schema #{target_schema} already has existing datasets named: #{target_schema_matching_dataset_names.join(',')}" unless target_schema_matching_dataset_names.empty?

      end

      def target_database_available_schemas
        Superset::Database::GetSchemas.call(target_database_id)
      end

      def source_dashboard_has_more_than_one_schema?
        source_dashboard_schemas.count > 1
      end

      # Pull the Datasets for all charts on the source dashboard
      def source_dashboard_schemas
        source_dashboard_datasets.map { |dataset| dataset[:schema] }.uniq
      end

      def source_dashboard_dataset_names
        source_dashboard_datasets.map { |dataset| dataset[:datasource_name] }.uniq
      end

      # identify any already existing datasets in the target schema that have the same name as the source dashboard datasets
      # note this is prior to adding the (COPY) suffix
      # here we will need to decide if we want to use the existing dataset or not see NEP-????
      # for now we will exit with an error if we find any existing datasets of the same name
      def target_schema_matching_dataset_names
        source_dashboard_dataset_names.map do |source_dataset_name|
          existing_names = Superset::Dataset::List.new(title_contains: source_dataset_name, schema_equals: target_schema).result.map{|t|t['table_name']}.uniq # contains match to cover with suffix as well
          unless existing_names.flatten.empty?
            logger.error "  HALTING PROCESS: Schema #{target_schema} already has Dataset called #{existing_names}"
          end
          existing_names
        end.flatten.compact
      end

      def logger
        @logger ||= Superset::Logger.new
      end

      def start_log_msg
        logger.info ""
        logger.info ">>>>>>>>>>>>>>>>> Starting DuplicateDashboard Service <<<<<<<<<<<<<<<<<<<<<<"
        logger.info "Ready Superset Host: #{ENV['SUPERSET_HOST']}"
        logger.info "Duplicating dashboard #{source_dashboard_id} into Target Schema: #{target_schema} in database #{target_database_id}"
      end

      def end_log_message
        logger.info "Duplication Successful. New Dashboard URL: #{new_dashboard.url} "
        logger.info ">>>>>>>>>>>>>>>>> Finished DuplicateDashboard Service <<<<<<<<<<<<<<<<<<<<<<"
      end
    end
  end
end