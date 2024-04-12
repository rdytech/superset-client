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

        puts "\n ====== DASHBOARD DATASETS ====== "
        Superset::Dashboard::Datasets::List.new(first_dashboard_id).list
        Superset::Dashboard::Datasets::List.new(second_dashboard_id).list

        puts "\n ====== DASHBOARD CHARTS ====== "
        Superset::Dashboard::Charts::List.new(first_dashboard_id).list
        puts ''
        Superset::Dashboard::Charts::List.new(second_dashboard_id).list

        puts "\n ====== DASHBOARD NATIVE FILTERS ====== "
        list_filters(first_dashboard)
        puts ''
        list_filters(second_dashboard)

        puts "\n ====== DASHBOARD CROSS FILTERS ====== "
        list_cross_filters(first_dashboard)
        puts ''
        list_cross_filters(second_dashboard)
      end

      def first_dashboard
        @first_dashboard ||= Get.new(first_dashboard_id).result
      end

      def second_dashboard
        @second_dashboard ||= Get.new(second_dashboard_id).result
      end

      def list_charts
        puts ' >>>> Dashboard Charts <<<<'
        Superset::Dashboard::Charts::List.new(first_dashboard_id).list
        Superset::Dashboard::Charts::List.new(second_dashboard_id).list
      end

      def native_filter_configuration(dashboard_result)
        rows = []
        JSON.parse(dashboard_result['json_metadata'])['native_filter_configuration'].each do |filter|
          filter['targets'].each {|t| rows << [ t['column']['name'], t['datasetId'] ] }
        end
        rows
      end

      def list_filters(dashboard_result)
        puts Terminal::Table.new(
          title: [dashboard_result['id'], dashboard_result['dashboard_title']].join(' - '),
          headings: ['Filter Name', 'Dataset Id'],
          rows: native_filter_configuration(dashboard_result)
        )
      end

      def cross_filter_configuration(dashboard_result)
        JSON.parse(dashboard_result['json_metadata'])['chart_configuration'].map {|k, v| [ v['id'], v['crossFilters'].to_s ] }
      end

      def list_cross_filters(dashboard_result)
        puts Terminal::Table.new(
          title: [dashboard_result['id'], dashboard_result['dashboard_title']].join(' - '),
          headings: ['Chart Id', 'Cross Filter Config'],
          rows: cross_filter_configuration(dashboard_result)
        )
      end
    end
  end
end
