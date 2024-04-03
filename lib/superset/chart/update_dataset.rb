# In the context of a chart, dataset and datasource are the same thing

module Superset
  module Chart
    class UpdateDataset < Superset::Request

      attr_reader :chart_id, :target_dataset_id

      def initialize(chart_id: , target_dataset_id: )
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
          new_params.merge!("owners": chart.owner_ids )                  # expects an array of user ids

          new_params.merge!("params": updated_chart_params.to_json)      # updated to point to the new params
          query_context = updated_chart_query_context
          if query_context
            new_params.merge!("query_context": query_context.to_json) # update to point to the new query context
            new_params.merge!("query_context_generation": true)            # new param set to true to regenerate the query context
          end
         
          new_params
        end
      end

      private

      def chart
        @chart ||= Superset::Chart::Get.new(chart_id).perform
      end

      def validate_proposed_changes
        raise "Error: chart_id integer is required" unless chart_id.present? && chart_id.is_a?(Integer)
        raise "Error: target_dataset_id integer is required" unless target_dataset_id.present? && target_dataset_id.is_a?(Integer)
        # validate schema ???
      end

      def updated_chart_params
        chart_params = chart.params # init with source chart params
        chart_params['datasource'] = chart_params['datasource'].sub(source_dataset_id.to_s, target_dataset_id.to_s) # update to point to the new dataset
        chart_params
      end

      def updated_chart_query_context
        if chart.query_context.present?                                           # not all charts have a query context
          chart_query_context = chart.query_context                               # init with source chart query context
          chart_query_context['datasource']['id'] = target_dataset_id             # update to point to the new dataset
          chart_query_context['form_data']['datasource'] = chart_query_context['form_data']['datasource']
            .sub(source_dataset_id.to_s, target_dataset_id.to_s) # update to point to the new dataset
          chart_query_context
        end
      end

      def source_dataset_id
        chart.datasource_id
      end

      def route
        "chart/#{chart_id}"
      end
    end
  end
end
