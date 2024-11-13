module Superset
  module Dashboard
    module Filters
      class List < Superset::Request
        attr_reader :id

        def initialize(id)
          @id = id
        end

        def perform
          filters_configuration = JSON.parse(dashboard.result['json_metadata'])['native_filter_configuration'] || []
          return Array.new unless filters_configuration && filters_configuration.any?
  
          # pull only the filters dataset ids from the dashboard
          filters_configuration.map { |c| c['targets'] }.flatten.compact.map { |c| c['datasetId'] }.flatten.compact
        end

        private

        def dashboard
          dashboard ||= Superset::Dashboard::Get.new(id)
        end
      end
    end
  end
end