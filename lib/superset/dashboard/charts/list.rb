module Superset
  module Dashboard
    module Charts
      class List < Superset::Request
        attr_reader :id  # dashboard id

        def self.call(id)
          self.new(id).list
        end

        def initialize(id)
          @id = id
        end

        def chart_ids
          result.map { |c| c[:id] }
        end

        private

        def route
          "dashboard/#{id}/charts"
        end

        def list_attributes
          ['id', 'slice_name', 'dashsource', 'dashboards'].map(&:to_sym)
        end

        def rows
          result.map do |c|
            [
              c[:id],
              c[:slice_name],
              c[:form_data][:datasource],
              c[:form_data][:dashboards]
            ]
          end
        end

        # when displaying a list of datasets, show dashboard title as well
        def title
          @title ||= Superset::Dashboard::Get.new(id).title
        end
      end
    end
  end
end
