# WARNING: Does not take into account datasets with queries that have embedded schema references.
# ie " select * from schema1.table join schema2.table" for a dataset query will ONLY return the datasets config schema setting not the sql query schema references which refers to 2 distinct schemas.
#
# WARNING: Does not return Filter Datasets for the dashboard

module Superset
  module Dashboard
    module Datasets
      class List < Superset::Request
        attr_reader :dashboard_id, :include_filter_datasets, :include_catalog_lookup # id - dashboard id

        def initialize(dashboard_id:, include_filter_datasets: false, include_catalog_lookup: false)
          @dashboard_id = dashboard_id
          @include_filter_datasets = include_filter_datasets
          @include_catalog_lookup = include_catalog_lookup
        end

        def perform
          response
          self
        end

        def datasets_details
          @datasets_details ||= begin
            datasets_list = chart_datasets + additional_filter_datasets
            datasets_list = include_catalog_details(datasets_list) if include_catalog_lookup
            datasets_list.compact
          end
        end

        def databases
          @databases ||= datasets_details.map {|d| d[:database] }.uniq
        end

        def catalogs
          datasets_details.map {|d| d[:catalog] }.compact.uniq
        end

        def schemas
          datasets_details.map {|d| d[:schema] }.compact.uniq
        end

        def rows
          datasets_details.map do |d|
            [
              d[:id],
              d[:datasource_name],
              d[:database][:id],
              d[:database][:name],
              d[:database][:backend],
              d[:schema],
              d[:filter_only]
            ]
          end
        end

        private

        def include_catalog_details(datasets_list)
          datasets_list.each {|d| d[:catalog] = Superset::Dataset::Get.new(d[:id].to_i).result['catalog'] }
        end

        # list of chart dataset details used in the dashboard
        def chart_datasets
          result.map do |details|
            details.slice('id', 'datasource_name', 'schema', 'sql').merge('database' => details['database'].slice('id', 'name', 'backend')).with_indifferent_access
          end
        end

        # list of any additional filter dataset details on the dashboard that are not used in charts
        def additional_filter_datasets
          return [] unless include_filter_datasets

          chart_dataset_ids = chart_datasets.map{|d| d['id'] }
          filter_dataset_ids_not_used_in_charts = filter_dataset_ids - chart_dataset_ids
          filter_dataset_ids_not_used_in_charts.empty? ? [] : retrieve_filter_datasets(filter_dataset_ids_not_used_in_charts)
        end

        def filter_dataset_ids
          @filter_dataset_ids ||= dashboard.filter_configuration.map { |c| c['targets'] }.flatten.compact.map { |c| c['datasetId'] }.flatten.compact.uniq
        end

        def retrieve_filter_datasets(filter_dataset_ids_not_used_in_charts)
          filter_dataset_ids_not_used_in_charts.map do |filter_dataset_id|
            filter_dataset = Superset::Dataset::Get.new(filter_dataset_id).result
            { id: filter_dataset_id,
              datasource_name: filter_dataset['datasource_name'],
              schema: filter_dataset['schema'],
              sql: filter_dataset['sql'],
              database: {
                'id' => filter_dataset['database']['id'],
                'name' => filter_dataset['database']['database_name'],
                'backend' => filter_dataset['database']['backend'] },
              filter_only: true }.with_indifferent_access
          end
        end

        def route
          "dashboard/#{dashboard_id}/datasets"
        end

        def list_attributes
          ['id', 'datasource_name', 'database_id', 'database_name', 'database_backend', 'schema', 'filter_only'].map(&:to_sym)
        end

        # when displaying a list of datasets, show dashboard title as well
        def title
          @title ||= [dashboard_id, dashboard.title].join(' ')
        end

        def dashboard
          @dashboard ||= Superset::Dashboard::Get.new(dashboard_id)
        end
      end
    end
  end
end
