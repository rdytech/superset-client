# A validation checker for comparing dashboards.
# This class is used to compare two dashboards by their datasets, charts, native filters and cross filters.
# Output is displayed in a table format to the ruby console
# 
# Usage:  Superset::Dashboard::Compare.new(first_dashboard_id: 322, second_dashboard_id: 347).perform
#
module Superset
  module Dashboard
    class Compare

      attr_reader :first_dashboard_id, :second_dashboard_id

      def initialize(first_dashboard_id: , second_dashboard_id: )
        @first_dashboard_id = first_dashboard_id
        @second_dashboard_id = second_dashboard_id
      end


      def perform
        raise "Error: first_dashboard_id integer is required" unless first_dashboard_id.present? && first_dashboard_id.is_a?(Integer)
        raise "Error: second_dashboard_id integer is required" unless second_dashboard_id.present? && second_dashboard_id.is_a?(Integer)

        list_datasets
        list_charts
        list_native_filters
        list_cross_filters

      end

      def first_dashboard
        @first_dashboard ||= Get.new(first_dashboard_id).result
      end

      def second_dashboard
        @second_dashboard ||= Get.new(second_dashboard_id).result
      end

      def list_datasets
        puts "\n ====== DASHBOARD DATASETS ====== "
        Superset::Dashboard::Datasets::List.new(dashboard_id: first_dashboard_id).list
        Superset::Dashboard::Datasets::List.new(dashboard_id: second_dashboard_id).list
      end

      def list_charts
        puts "\n ====== DASHBOARD CHARTS ====== "
        Superset::Dashboard::Charts::List.new(first_dashboard_id).list
        puts ''
        Superset::Dashboard::Charts::List.new(second_dashboard_id).list
      end

      def list_native_filters
        puts "\n ====== DASHBOARD NATIVE FILTERS ====== "
        list_native_filters_for(first_dashboard)
        puts ''
        list_native_filters_for(second_dashboard)
      end

      def list_cross_filters
        puts "\n ====== DASHBOARD CROSS FILTERS ====== "
        list_cross_filters_for(first_dashboard)
        puts ''
        list_cross_filters_for(second_dashboard)
      end

      def native_filter_configuration(dashboard_result)
        rows = []
        JSON.parse(dashboard_result['json_metadata'])['native_filter_configuration'].each do |filter|
          filter['targets'].each do |t|
            if t['column']
              rows << [ filter['name'], t['column']['name'], t['datasetId'] ]
            else
              rows << [ filter['name'], '>NO DATASET LINKED<', t['datasetId'] ] # some filters don't have a dataset linked, ie date filter
            end
          end
        end
        rows
      end

      def list_native_filters_for(dashboard_result)
        puts Terminal::Table.new(
          title: [dashboard_result['id'], dashboard_result['dashboard_title']].join(' - '),
          headings: ['Filter Name', 'Dataset Column', 'Dataset Id'],
          rows: native_filter_configuration(dashboard_result)
        )
      end

      def cross_filter_configuration(dashboard_result)
        JSON.parse(dashboard_result['json_metadata'])['chart_configuration'].map {|k, v| [ v['id'], v['crossFilters'].to_s ] }
      end

      def list_cross_filters_for(dashboard_result)
        puts Terminal::Table.new(
          title: [dashboard_result['id'], dashboard_result['dashboard_title']].join(' - '),
          headings: ['Chart Id', 'Cross Filter Config'],
          rows: cross_filter_configuration(dashboard_result)
        )
      end
    end
  end
end
