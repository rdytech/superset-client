# Data Sovereignty validations are enforced, ie confirming
# - all charts datasets on the source dashboard are pointing to the same database schema
# - all filter datasets on the source dashboard are pointing to the same database schema as the charts

# - The source dashboard is in the same Superset instance as the target database and target schema


module Superset
  module Services
    class DuplicateDashboard < Superset::Request

      attr_reader :source_dashboard_id, :target_schema, :target_database_id, :allowed_domains, :tags, :publish

      def initialize(source_dashboard_id:, target_schema:, target_database_id: , allowed_domains: [], tags: [], publish: false)
        @source_dashboard_id = source_dashboard_id
        @target_schema = target_schema
        @target_database_id = target_database_id
        @allowed_domains = allowed_domains
        @tags = tags
        @publish = publish
      end

      def perform
        # validate all params before starting the process
        validate_params

        # Pull the Datasets for all charts on the source dashboard
        source_dashboard_datasets

        # create a new_dashboard by copying the source_dashboard using with 'duplicate_slices: true' to get a new set of charts.
        # The new_dashboard will have a copy of charts from the source_dashboard, but with the same datasets as the source_dashboard
        new_dashboard

        # Duplicate these Datasets to the new target schema and target database
        duplicate_source_dashboard_datasets

        # Update the Charts on the New Dashboard with the New Datasets and update the Dashboard json_metadata for the charts
        update_charts_with_new_datasets

        # Duplicate filters to the new target schema and target database
        duplicate_source_dashboard_filters

        update_source_dashboard_json_metadata

        created_embedded_config

        add_tags_to_new_dashboard

        publish_dashboard if publish

        end_log_message

        # return the new dashboard id and url
        { new_dashboard_id: new_dashboard.id, new_dashboard_url: new_dashboard.url, published: publish }

      rescue => e
        logger.error("#{e.message}")
        raise e
      end

      def new_dashboard_json_metadata_configuration
        @new_dashboard_json_metadata_configuration ||= new_dashboard.json_metadata
      end

      private

      def add_tags_to_new_dashboard
        return unless tags.present?

        Superset::Tag::AddToObject.new(object_type_id: ObjectType::DASHBOARD, object_id: new_dashboard.id, tags: tags).perform
        logger.info "  Added tags to dashboard #{new_dashboard.id}: #{tags}"
      rescue => e
        # catching tag error and display in log .. but also alowing the process to finish logs as tag error is fairly insignificant
        logger.error("  FAILED to add tags to new dashboard id: #{new_dashboard.id}. Error is #{e.message}")
        logger.error("  Missing Tags Values are #{tags}")
      end

      def created_embedded_config
        return unless allowed_domains.present?

        result = Dashboard::Embedded::Put.new(dashboard_id: new_dashboard.id, allowed_domains: allowed_domains).result
        logger.info "Added Embedded Settings to New Dashboard #{new_dashboard.id}:"
        logger.info "  Embedded Domain allowed_domains: #{result['allowed_domains']}"
        logger.info "  Embedded UUID: #{result['uuid']}"
      end

      def dataset_duplication_tracker
        @dataset_duplication_tracker ||= []
      end

      def duplicate_source_dashboard_datasets
        source_dashboard_datasets.each do |dataset|
          # duplicate the dataset, renaming to use of suffix as the target_schema
          # reason: there is a bug(or feature) in the SS API where a dataset name must be uniq when duplicating.  
          # (note however renaming in the GUI to a dup name works fine)
          new_dataset_name = "#{dataset[:datasource_name]}-#{target_schema}"
          existing_datasets = Superset::Dataset::List.new(title_equals: new_dataset_name, schema_equals: target_schema).result
          if existing_datasets.any?
            new_dataset_id = existing_datasets[0]["id"] # assuming that we do not name multiple datasets with same name in a single schema
          else
            new_dataset_id = Superset::Dataset::Duplicate.new(source_dataset_id: dataset[:id], new_dataset_name: new_dataset_name).perform
            # update the new dataset with the target schema and target database
            Superset::Dataset::UpdateSchema.new(source_dataset_id: new_dataset_id, target_database_id: target_database_id, target_schema: target_schema).perform
          end
          # keep track of the previous dataset and the matching new dataset_id
          dataset_duplication_tracker <<  { source_dataset_id: dataset[:id], new_dataset_id: new_dataset_id }
        end
      end

      def update_charts_with_new_datasets
        logger.info "Updating Charts to point to New Datasets and updating Dashboard json_metadata ..."
        # note dashboard json_metadata currently still points to the old chart ids and is updated here

        new_dashboard_json_metadata_json_string = new_dashboard_json_metadata_configuration.to_json # need to convert to string for gsub
        # get all chart ids for the new dashboard
        new_charts_list = Superset::Dashboard::Charts::List.new(new_dashboard.id).result
        new_chart_ids_list = new_charts_list&.map { |r| r['id'] }&.compact
        # get all chart details for the source dashboard
        original_charts = Superset::Dashboard::Charts::List.new(source_dashboard_id).result.map { |r| [r['slice_name'], r['id']] }.to_h
        new_charts = new_charts_list.map { |r| [r['id'], r['slice_name']] }.to_h
        return unless new_chart_ids_list.any?

        # for each chart, update the charts current dataset_id with the new dataset_id
        new_chart_ids_list.each do |new_chart_id|

          # get the CURRENT dataset_id for the new chart
          current_chart_dataset_id = Superset::Chart::Get.new(new_chart_id).datasource_id

          # find the new dataset_id for the new chart, based on the current_chart_dataset_id
          new_dataset_id = dataset_duplication_tracker.find { |dataset| dataset[:source_dataset_id] == current_chart_dataset_id }&.fetch(:new_dataset_id, nil)

          # update the new chart to target the new dataset_id and to the reference the new target_dashboard_id
          Superset::Chart::UpdateDataset.new(chart_id: new_chart_id, target_dataset_id: new_dataset_id, target_dashboard_id: new_dashboard.id).perform
          logger.info "  Update Chart #{new_chart_id} to new dataset_id #{new_dataset_id}"

          # update json metadata swaping the old chart_id with the new chart_id
          original_chart_id = original_charts[new_charts[new_chart_id]]
          regex_with_numeric_boundaries = Regexp.new("\\b#{original_chart_id.to_s}\\b")
          new_dashboard_json_metadata_json_string.gsub!(regex_with_numeric_boundaries, new_chart_id.to_s)
        end

        # convert back to hash .. and store in the new_dashboard_json_metadata_configuration
        @new_dashboard_json_metadata_configuration = JSON.parse(new_dashboard_json_metadata_json_string)
      end

      def duplicate_source_dashboard_filters
        return unless source_dashboard_filter_dataset_ids.length.positive?

        logger.info "Updating Filters to point to new dataset targets ..."
        configuration = new_dashboard_json_metadata_configuration['native_filter_configuration']&.map do |filter_config|
          targets = filter_config['targets']
          target_filter_dataset_id = dataset_duplication_tracker.find { |d| d[:source_dataset_id] == targets.first["datasetId"] }&.fetch(:new_dataset_id, nil)
          filter_config['targets'] = [targets.first.merge({ "datasetId"=> target_filter_dataset_id })]
          filter_config
        end

        @new_dashboard_json_metadata_configuration['native_filter_configuration'] = configuration || []
      end

      def update_source_dashboard_json_metadata
        logger.info "  Updated new Dashboard json_metadata charts with new dataset ids"
        Superset::Dashboard::Put.new(target_dashboard_id: new_dashboard.id, params: { "json_metadata" => @new_dashboard_json_metadata_configuration.to_json }).perform
      end

      def publish_dashboard
        Superset::Dashboard::Put.new(target_dashboard_id: new_dashboard.id, params: { published: publish } ).perform
      end

      def new_dashboard
        @new_dashboard ||= begin
          copy = Superset::Dashboard::Copy.new(
            source_dashboard_id:       source_dashboard_id,
            duplicate_slices:          true,
            clear_shared_label_colors: true
          ).perform
          logger.info("  Copy Dashboard/Charts Completed - New Dashboard ID: #{copy.id}")
          copy
        end
      rescue => e
        logger.info("  Dashboard::Copy error: #{e.message}")
        raise "Dashboard::Copy error: #{e.message}"
      end

      # retrieve the datasets that will be duplicated
      def source_dashboard_datasets
        @source_dashboard_datasets ||= Superset::Dashboard::Datasets::List.new(dashboard_id: source_dashboard_id, include_filter_datasets: true).datasets_details
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
        raise ValidationError, "The source dashboard datasets are required to point to one schema only. Actual schema list is #{source_dashboard_schemas.join(',')}" if source_dashboard_has_more_than_one_schema?
        raise ValidationError, "One or more source dashboard filters point to a different schema than the dashboard charts. Identified Unpermittied Filter Dataset Ids are #{unpermitted_filter_dataset_ids.to_s}" if unpermitted_filter_dataset_ids.any?

        # new dataset validations
        raise ValidationError, "DATASET NAME CONFLICT: The Target Schema #{target_schema} already has existing datasets named: #{target_schema_matching_dataset_names.join(',')}" unless target_schema_matching_dataset_names.empty?
        validate_source_dashboard_datasets_sql_does_not_hard_code_schema

        # embedded allowed_domain validations
        raise  InvalidParameterError, 'allowed_domains array is required' if allowed_domains.nil? || allowed_domains.class != Array
      end

      def validate_source_dashboard_datasets_sql_does_not_hard_code_schema
        errors = source_dashboard_datasets.map do |dataset|
          "The Dataset ID #{dataset[:id]} SQL query is hard coded with the schema value and can not be duplicated cleanly.  " +
            "Remove all direct embedded schema calls from the Dataset SQL query before continuing." if dataset[:sql].include?("#{dataset[:schema]}.")
        end.compact
        raise ValidationError, errors.join("\n") unless errors.empty?
      end

      def source_dashboard
        @source_dashboard ||= Superset::Dashboard::Get.new(source_dashboard_id)
      end

      def target_database_available_schemas
        Superset::Database::GetSchemas.call(target_database_id)
      end

      def source_dashboard_has_more_than_one_schema?
        source_dashboard_schemas.count > 1
      end

      # Data Sovereignty rules expect only 1 value here, and raise a validation error if there is > 1
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

      def source_dashboard_dataset_ids
        source_dashboard_datasets.map{|d|d['id']}
      end

      def source_dashboard_filter_dataset_ids
        @filter_dataset_ids ||= Superset::Dashboard::Filters::List.new(id).perform
      end

      # Primary Assumption is that all charts datasets on the source dashboard are pointing to the same database schema
      # An unpermitted filter will have a dataset that is pulling data from a datasource that is
      # different to the dashboard charts database schema
      def unpermitted_filter_dataset_ids
        @unpermitted_filter_dataset_ids ||= begin
          filter_datasets_not_used_in_charts = source_dashboard_filter_dataset_ids - source_dashboard_dataset_ids

          # retrieve any filter_datasets_not_used_in_charts that do not match the source_dashboard_schema
          filter_datasets_not_used_in_charts.map do |filter_dataset|
            filter_dataset_schema = Superset::Dataset::Get.new(filter_dataset).schema
            # return any filter datasets not used in charts that are from a different schema
            {  filter_dataset_id: filter_dataset, filter_schema: filter_dataset_schema  } if [filter_dataset_schema] != source_dashboard_schemas
          end.compact
        end
      end

      def logger
        @logger ||= Superset::Logger.new
      end

      def start_log_msg
        logger.info ""
        logger.info ">>>>>>>>>>>>>>>>> Starting DuplicateDashboard Service <<<<<<<<<<<<<<<<<<<<<<"
        logger.info "Source Dashboard URL: #{source_dashboard.url}"
        logger.info "Duplicating dashboard #{source_dashboard_id} into Target Schema: #{target_schema} in database #{target_database_id}"
      end

      def end_log_message
        logger.info "Duplication Successful. New Dashboard URL: #{new_dashboard.url} "
        logger.info ">>>>>>>>>>>>>>>>> Finished DuplicateDashboard Service <<<<<<<<<<<<<<<<<<<<<<"
      end
    end
  end
end
