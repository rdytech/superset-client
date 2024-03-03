# In the context of a chart, dataset and datasource are the same thing

module Superset
  module Chart
    class UpdateDataset < Superset::Request

      attr_reader :chart_id, :target_dataset_id

      def initialize(chart_id: 135, target_dataset_id: 54093)
        @chart_id = chart_id
        @target_dataset_id = target_dataset_id
      end

      def perform
        validate_proposed_changes

        response

        # TODO .. check the response for success
        if result['datasource'] == target_dataset_id
          puts "Successfully updated chart #{chart_id} to the target dataset #{target_dataset_id}"
        else
          puts "Error: Failed to update chart #{chart_id} to #{target_dataset_id}"
        end

      end

      def response
        @response ||= client.put(route, params_updated)
      end

      def params_updated
        @params_updated ||= begin
          new_params = chart.slice(*acceptable_attributes).with_indifferent_access
          
          # chart updates to point to the new target dataset
          new_params.merge!("datasource_id": target_dataset_id)          # point to the new dataset id
          new_params.merge!("datasource_type": 'table')                  # type of dataset ?? not sure of other options
          new_params.merge!("owners": chart['owners'].map{|o| o['id']} ) # expects an array of user ids
          new_params.merge!("dashboards": chart['dashboards'].map{|o| o['id']} ) # expects an array of dashboards ids

          new_params.merge!("params": updated_source_attribute_params_to_new_dataset_id.to_json) # updated to point to the new dataset
          new_params.merge!("query_context": updated_source_attribute_query_context_to_new_dataset_id.to_json) # update to point to the new dataset
          new_params.merge!("query_context_generation": true)            # new param set to true to regenerate the query context .. unsure of the impact of this
         
          new_params
        end
      end

      # private

      def chart
        # will raise an error if the chart does not exist
        @chart ||= begin
          chart = Superset::Chart::Get.new(chart_id)
          chart.result[0]
        end
      end

      def validate_proposed_changes
        raise "Error: chart_id integer is required" unless chart_id.present? && chart_id.is_a?(Integer)
        raise "Error: target_dataset_id integer is required" unless target_dataset_id.present? && target_dataset_id.is_a?(Integer)

        # confirm the chart exists? ... no need as the source_dataset method will raise an error if the dataset does not exist

      end

      def source_attribute_params
        @source_attribute_params ||= JSON.parse(chart['params'])
      end

      def updated_source_attribute_params_to_new_dataset_id
        source_attribute_params['datasource'] = source_attribute_params['datasource'].
          sub(source_dataset_id.to_s, target_dataset_id.to_s)
          
        source_attribute_params
      end

      def source_attribute_query_context
        @source_attribute_query_context ||= JSON.parse(chart['query_context'])
      end

      def updated_source_attribute_query_context_to_new_dataset_id
        source_attribute_query_context['datasource']['id'] = target_dataset_id
        source_attribute_query_context['form_data']['datasource'] = source_attribute_query_context['form_data']['datasource'].
          sub(source_dataset_id.to_s, target_dataset_id.to_s)

        source_attribute_query_context
      end


      def source_dataset_id
        JSON.parse(chart['query_context'])['datasource']['id']
      end

      # attrs as per swagger docs for chart patch
      def acceptable_attributes
        %w(
          cache_timeout
          certification_details
          certified_by
          dashboards
          datasource_id
          datasource_type
          description
#          external_url  # not in source params .. possibly not required ?
          is_managed_externally
          owners
          params
          query_context            # possibly set to empty .. so its regenerated 
#          query_context_generation # new param set to true to regenerate the query context
          slice_name
          tags
          viz_type
        )
      end

      def route
        "chart/#{chart_id}"
      end

      def target_database_available_schemas
        Superset::Database::GetSchemas.call(target_database_id)
      end
    end
  end
end
