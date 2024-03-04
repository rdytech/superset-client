# In the context of a chart, dataset and datasource are the same thing

module Superset
  module Chart
    class UpdateDataset < Superset::Request

      attr_reader :chart_id, :target_dataset_id

      def initialize(chart_id: :chart_id, target_dataset_id: :target_dataset_id)
        @chart_id = chart_id
        @target_dataset_id = target_dataset_id
      end

      def perform
        validate_proposed_changes

        response

        if result['datasource_id'] == target_dataset_id
          "Successfully updated chart #{chart_id} to the target dataset #{target_dataset_id}"
        else
          "Error: Failed to update chart #{chart_id} to #{target_dataset_id}"
        end

      end

      def response
        @response ||= client.put(route, params_updated)
      end

      def params_updated
        @params_updated ||= begin
          new_params = {}
          
          # chart updates to point to the new target dataset
          new_params.merge!("datasource_id": target_dataset_id)          # point to the new dataset id
          new_params.merge!("datasource_type": 'table')                  # type of dataset ?? not sure of other options
          new_params.merge!("owners": chart['owners'].map{|o| o['id']} ) # expects an array of user ids

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

      def route
        "chart/#{chart_id}"
      end
    end
  end
end
