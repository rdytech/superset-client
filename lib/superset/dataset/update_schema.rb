module Superset
  module Dataset
    class UpdateSchema < Superset::Request

      attr_reader :source_dataset_id, :target_database_id, :target_schema, :remove_copy_suffix

      def initialize(source_dataset_id: , target_database_id: , target_schema: , remove_copy_suffix: false)
        @source_dataset_id = source_dataset_id
        @target_database_id = target_database_id
        @target_schema = target_schema
        @remove_copy_suffix = remove_copy_suffix
      end

      def perform
        validate_proposed_changes

        response

        msg = if result['schema'] == target_schema
          "Successfully updated dataset schema to #{target_schema} on Database: #{target_database_id}"
        else
          "Error: Failed to update dataset schema to #{target_schema} on Database: #{target_database_id}"
        end

        logger.info "    #{msg}"
        msg

      end

      def response
        @response ||= client.put(route, params_updated)
      end

      def params_updated
        @params_updated ||= begin
          new_params = source_dataset.slice(*acceptable_attributes).with_indifferent_access
          
          # primary database and schema changes
          new_params.merge!("database_id": target_database_id)  # add the target database id
          new_params['schema'] = target_schema
          new_params['owners'] = new_params['owners'].map {|o| o['id'] } # expects an array of user ids
          new_params['table_name'] = new_params['table_name'].gsub(/ \(COPY\)/, '') if remove_copy_suffix

          # remove unwanted fields from metrics and columns arrays
          new_params['metrics'].each {|m| m.delete('changed_on') }
          new_params['metrics'].each {|m| m.delete('created_on') }
          new_params['columns'].each {|m| m.delete('changed_on') }
          new_params['columns'].each {|m| m.delete('created_on') }
          new_params['columns'].each {|m| m.delete('type_generic') }
          new_params
        end
      end

      # check if the sql query embedds the schema name, if so it can not be duplicated cleanly
      def sql_query_includes_hard_coded_schema?
        source_dataset['sql'].include?("#{source_dataset['schema']}.")
      end

      private

      def source_dataset
        # will raise an error if the dataset does not exist
        @source_dataset ||= begin
          dataset = Get.new(source_dataset_id)
          dataset.result
        end
      end

      def validate_proposed_changes
        logger.info "    Validating Dataset ID: #{source_dataset_id} schema update to #{target_schema} on Database: #{target_database_id}"
        raise "Error: source_dataset_id integer is required"  unless source_dataset_id.present? && source_dataset_id.is_a?(Integer)
        raise "Error: target_database_id integer is required" unless target_database_id.present? && target_database_id.is_a?(Integer)
        raise "Error: target_schema string is required"       unless target_schema.present? && target_schema.is_a?(String)

        # confirm the dataset exist? ... no need as the load_source_dataset method will raise an error if the dataset does not exist
 
        # does the target schema exist in the target database?
        raise "Error: Schema #{target_schema} does not exist in database: #{target_database_id}" unless target_database_available_schemas.include?(target_schema)

        # does the sql query hard code the current schema name?
        raise "Error: >>WARNING<< The Dataset ID #{source_dataset_id} SQL query is hard coded with the schema value and can not be duplicated cleanly.  " +
              "Remove all direct embedded schema calls from the Dataset SQL query before continuing." if sql_query_includes_hard_coded_schema?
      end

      # attrs as per swagger docs for dataset patch
      def acceptable_attributes
        %w(
          always_filter_main_dttm
          cache_timeout
          columns
          database_id
          default_endpoint
          description
          extra
          fetch_values_predicate
          filter_select_enabled
          is_managed_externally
          is_sqllab_view
          main_dttm_col
          metrics
          normalize_columns
          offset
          owners
          schema
          sql
          table_name
          template_params
        )
      end

      def route
        "dataset/#{source_dataset_id}"
      end

      def target_database_available_schemas
        Superset::Database::GetSchemas.call(target_database_id)
      end
    end
  end
end
