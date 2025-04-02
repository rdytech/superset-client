# Creates a log report on a set of dashboards
# providing count of charts, datasets, and databases used in each dashboard
# as well as optional data sovereignty information

# Data Sovereignty in this context requires that all datasets used in a dashboard are from one database schema only.
# Primarily used to identify potential issues with embedded dashboards where data sovereignty is a concern.

# Usage:
# Superset::Services::DashboardReport.new(dashboard_ids: [1,2,3]).perform

module Superset
  module Services
    class DashboardReport

      attr_reader :dashboard_ids, :report_on_data_sovereignty_only

      def initialize(dashboard_ids: [], report_on_data_sovereignty_only: true)
        @dashboard_ids = dashboard_ids
        @report_on_data_sovereignty_only = report_on_data_sovereignty_only
      end

      def perform
        create_dashboard_report
        load_data_sovereignty_issues
        
        report_on_data_sovereignty_only ? display_data_sovereignty_report : @report
      end

      private

      def display_data_sovereignty_report
        # filter by dashboards where 
        # 1. A filter dataset is not part of the dashboard datasets (might be ok for some cases, ie a dummy dataset listing dates only)
        # 2. There is more than one distinct dataset schema (never ok for embedded dashboards where the expected schema num is only one)

        puts "Data Sovereignty Report"
        puts "-----------------------"
        puts "Possible Invalid Dashboards: #{@data_sovereignty_issues.count}"
        @data_sovereignty_issues
      end

      # possible data sovereignty issues
      def load_data_sovereignty_issues
        @data_sovereignty_issues ||= begin
          @report.map do |dashboard|
            reasons = []
            chart_dataset_ids = dashboard[:datasets][:chart_datasets].map{|d| d[:id]}

            # add WARNING msg if any filters datasets are not part of the chart datasets
            unknown_datasets = dashboard[:filters][:filter_dataset_ids] - chart_dataset_ids
            if unknown_datasets.any?
              reasons << "WARNING: One or more filter datasets is not included in chart datasets for " \
                          "filter dataset ids: #{unknown_datasets.join(', ')}."
              reasons << "DETAILS: #{unknown_dataset_details(unknown_datasets)}"
            end

            # add ERROR msg if multiple chart dataset schemas are found, ie all datasets should be sourced from the same db schema
            chart_dataset_schemas = dashboard[:datasets][:chart_datasets].map{|d| d[:schema]}.uniq
            if chart_dataset_schemas.count > 1
              reasons << "ERROR: Multiple distinct chart dataset schemas found. Expected 1. Found #{chart_dataset_schemas.count}. " \
                          "schema names: #{chart_dataset_schemas.join(', ') }"
            end

            { reasons: reasons, dashboard: dashboard } if reasons.any?
          end.compact
        end
      end

      def unknown_dataset_details(unknown_datasets)
        unknown_datasets.map do |dataset_id|
          d = Superset::Dataset::Get.new(dataset_id)
          d.result
          { id: d.id, name: d.title }
        rescue Happi::Error::NotFound => e
          { id: dataset_id, name: '>>>> ERROR: DATASET DOES NOT EXIST <<<<' }
        end
      end

      def create_dashboard_report
        @report ||= begin
          dashboard_ids.map do |dashboard_id|
            dashboard = dashboard_result(dashboard_id)
            {
              dashboard_id: dashboard_id,
              dashboard_title: dashboard['dashboard_title'],
              dashboard_url: dashboard['url'],
              dashboard_tags: dashboard_tags(dashboard),
              filters: filter_details(dashboard),
              charts: chart_count(dashboard),
              datasets: dataset_details(dashboard_id),
            }
          end
        end
      end

      def filter_details(dashboard)
        { 
          filter_count: filter_count(dashboard),
          filter_dataset_ids: filter_datasets(dashboard)
        }
      end

      def filter_count(dashboard)
        dashboard['json_metadata']['native_filter_configuration']&.count || 0
      end

      def filter_datasets(dashboard)
        dashboard['json_metadata']['native_filter_configuration'].map do |filter|
          filter['targets'].map{|d| d['datasetId']} if filter['type'] == 'NATIVE_FILTER'
        end.flatten.compact.uniq
      end

      def chart_count(dashboard)
        dashboard['json_metadata']['chart_configuration'].count
      end

      def dataset_details(dashboard_id)
        datasets = Superset::Dashboard::Datasets::List.new(dashboard_id: dashboard_id).rows_hash
        { 
          dataset_count: datasets.count,
          chart_datasets: datasets
        }
      end

      def dashboard_tags(dashboard)
        dashboard['tags'].map{|t| t['name']}.join('|')
      end

      def dashboard_result(dashboard_id)
       # convert json_metadata within result to a hash
       board = Superset::Dashboard::Get.new(dashboard_id)
       board.result['json_metadata'] = JSON.parse(board.result['json_metadata'])
       board.result['url'] = board.url # add full url to the dashboard result
       board.result
      end
    end
  end
end
