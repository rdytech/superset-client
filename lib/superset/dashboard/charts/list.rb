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

        private

        def route
          "dashboard/#{id}/charts"
        end

        def list_attributes
          ['id', 'slice_name', 'datasource', 'dashboards'].map(&:to_sym)
        end

        # when displaying a list of datasets, show dashboard id and title as well
        def title
          @title ||= [id, Superset::Dashboard::Get.new(id).title].join(' ')
        end
      end
    end
  end
end
