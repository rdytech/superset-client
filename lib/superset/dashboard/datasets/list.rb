# WARNING: Does not take into account datasets with queries that have embedded schema references.
# ie " select * from schema1.table join schema2.table" for a dataset query will ONLY return the datasets config schema setting not the sql query schema references which refers to 2 distinct schemas.
#
# WARNING: Does not return Filter Datasets for the dashboard

module Superset
  module Dashboard
    module Datasets
      class List < Superset::Request
        attr_reader :id, :include_filter_datasets # id - dashboard id

        def self.call(id)
          self.new(id).list
        end

        def initialize(dashboard_id:, include_filter_datasets: false)
          @id = dashboard_id
          @include_filter_datasets = include_filter_datasets
        end

        def perform
          response
          self
        end

        def schemas
          @schemas ||= begin
            all_dashboard_schemas = result.map {|d| d[:schema] }.uniq

            # For the current superset setup we will assume a dashboard datasets will point to EXACTLY one schema, their own.
            # if not .. we need to know about it. Potentially we could override this check if others do not consider it a problem.
            if all_dashboard_schemas.count > 1
              Rollbar.error("SUPERSET DASHBOARD ERROR: Dashboard id #{id} has multiple dataset schema linked: #{all_dashboard_schemas.to_s}")
            end
            all_dashboard_schemas
          end
        end

        def datasets_details
          chart_datasets = result.map do |details|
            details.slice('id', 'datasource_name', 'schema', 'sql').merge('database' => details['database'].slice('id', 'name', 'backend')).with_indifferent_access
          end
          return chart_datasets unless include_filter_datasets
          chart_dataset_ids = chart_datasets.map{|d| d['id'] }
          filter_dataset_ids_not_used_in_charts = filter_dataset_ids - chart_dataset_ids
          return chart_datasets if filter_dataset_ids_not_used_in_charts.empty?
          # returning chart and filter datasets
          chart_datasets + filter_datasets(filter_dataset_ids_not_used_in_charts)
        end

        private

        def filter_dataset_ids
          @filter_dataset_ids ||= dashboard.filter_configuration.map { |c| c['targets'] }.flatten.compact.map { |c| c['datasetId'] }.flatten.compact.uniq
        end

        def filter_datasets(filter_dataset_ids_not_used_in_charts)
          filter_dataset_ids_not_used_in_charts.map do |filter_dataset_id|
            filter_dataset = Superset::Dataset::Get.new(filter_dataset_id).result
            database_info = {
              'id' => filter_dataset['database']['id'],
              'name' => filter_dataset['database']['database_name'],
              'backend' => filter_dataset['database']['backend']
            }
            filter_dataset.slice('id', 'datasource_name', 'schema', 'sql').merge('database' => database_info, 'filter_only': true).with_indifferent_access
          end
        end

        def route
          "dashboard/#{id}/datasets"
        end

        def list_attributes
          ['id', 'datasource_name', 'database_id', 'database_name', 'database_backend', 'schema', 'filter_only'].map(&:to_sym)
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

        # when displaying a list of datasets, show dashboard title as well
        def title
          @title ||= [id, dashboard.title].join(' ')
        end

        def dashboard
          @dashboard ||= Superset::Dashboard::Get.new(id)
        end
      end
    end
  end
end
