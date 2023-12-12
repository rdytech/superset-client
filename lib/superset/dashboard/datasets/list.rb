module Superset
  module Dashboard
    module Datasets
      class List < Superset::Request
        attr_reader :id  # dashboard id

        def self.call(id)
          self.new(id).list
        end

        def initialize(id)
          @id = id
        end

        def schemas
          @schemas ||= begin
            all_dashboard_schemas = result.map {|d| d[:schema] }.uniq

            # For the current superset setup we will assume a dashboard datasets will point to EXACTLY one schema, their own.
            # if not .. we need to know about it
            if all_dashboard_schemas.count > 1
              Rollbar.error("SUPERSET DASHBOARD ERROR: Dashboard id #{id} has multiple dataset schema linked: #{all_dashboard_schemas.to_s}")
            end
            all_dashboard_schemas
          end
        end

        private

        def route
          "dashboard/#{id}/datasets"
        end

        def list_attributes
          ['id', 'datasource_name', 'database_id', 'database_name', 'database_backend', 'schema'].map(&:to_sym)
        end

        def rows
          result.map do |d|
            [
              d[:id],
              d[:datasource_name],
              d[:database][:id],
              d[:database][:name],
              d[:database][:backend],
              d[:schema]
            ]
          end
        end

        # when displaying a list of datasets, show dashboard title as well
        def title
          Superset::Dashboard::Get.new(id).title
        end
      end
    end
  end
end