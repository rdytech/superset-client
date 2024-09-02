# There is no API endpoint to duplicate charts in Superset. 
# This class is a workaround.
# Requires a source chart id, target dataset id

module Superset
  module Chart
    class Duplicate < Superset::Request

      attr_reader :source_chart_id, :target_dataset_id, :new_chart_name

      def initialize(source_chart_id: , target_dataset_id: , new_chart_name:  )
        @source_chart_id = source_chart_id
        @target_dataset_id = target_dataset_id
        @new_chart_name = new_chart_name
      end

      def perform
        raise "Error: source_chart_id integer is required" unless source_chart_id.present? && source_chart_id.is_a?(Integer)
        raise "Error: target_dataset_id integer is required" unless target_dataset_id.present? && target_dataset_id.is_a?(Integer)
        raise "Error: new_chart_name string is required" unless new_chart_name.present? && new_chart_name.is_a?(String)

        logger.info("Duplicating Chart #{source_chart_id}:#{source_chart['slice_name']}. New chart dataset #{target_dataset_id} and new chart name #{new_chart_name}")
        Superset::Chart::Create.new(params: new_chart_params).perform
      end

      private

    def new_chart_params
      # pulled list from Swagger GUI for chart POST request
      # commented out params seem to be not required .. figured out by trial and error
      {
        #"cache_timeout": 0,
        #"certification_details": "string",
        #"certified_by": "string",
        #"dashboards": [ 0 ],
        "datasource_id": target_dataset_id,
    #   "datasource_name": new_chart_name,
        "datasource_type": "table",
    #    "description": "",
    #    "external_url": "string",
    #    "is_managed_externally": true,
    #    "owners": [ 3 ],                          # TODO .. check if this is a Required attr, might need to get current API users id.
        "params": new_chart_internal_params,
        "query_context": new_chart_internal_query_context,
        "query_context_generation": true,
        "slice_name": new_chart_name,
        "viz_type": source_chart['viz_type']
      }
    end

    def new_chart_internal_params
      new_params = JSON.parse(source_chart['params'])
      new_params['datasource'] =  new_params['datasource'].gsub(source_chart_dataset_id.to_s, target_dataset_id.to_s)
      new_params.delete('slice_id') # refers to the source chart id .. a new id will be generated in the new chart
      new_params.to_json
    end

    def new_chart_internal_query_context
      new_query_context = JSON.parse(source_chart['query_context'])
      new_query_context['datasource'] =  new_query_context['datasource']['id'] = target_dataset_id
      new_query_context['form_data']['datasource'] = new_query_context['form_data']['datasource'].gsub(source_chart_dataset_id.to_s, target_dataset_id.to_s)
      new_query_context['form_data'].delete('slice_id')
      new_query_context.to_json
    end

      def source_chart
        @source_chart ||= Superset::Chart::Get.new(source_chart_id).result[0]
      end

      def source_chart_dataset_id
        @source_chart_dataset_id ||= JSON.parse(source_chart[:query_context])['datasource']['id']
      end
    end
  end
end
