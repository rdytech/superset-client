module Superset
  module Dashboard
    class List < Superset::Request
      attr_reader :title_contains

      def initialize(page_num: 0, title_contains: '')
        @title_contains = title_contains
        super(page_num: page_num)
      end

      def self.call
        self.new.list
      end

      def all
        result.map do |d|
          OpenStruct.new(
            list_attributes.map { |la| [la, d[la]] }.to_h
              # merge(retrieve_schemas(d[:id])).            # WIP
              # merge(retrieve_embedded_details(d[:id]))    # WIP
            )
        end
      end

# Coming soon ... requires other classes to be implemented first.
#      # TODO: currently in SS v2.1 there is no way to get a list of all dashboards schemas easily
#      # so we have to make a separate request for each dashboard to retrieve any associated datasets schemas.
#      def retrieve_schemas(id)
#        { schemas: Datasets::List.new(id).schemas }
#      end
#
#      def retrieve_embedded_details(id)
#        embedded_dashboard = Dashboard::Embedded::Get.new(id)
#        { allowed_embedded_domains: embedded_dashboard.allowed_domains,
#          uuid: embedded_dashboard.uuid,}
#      end

      private

      def route
        "dashboard/?q=(#{query_params})"
      end

      def filters
        "filters:!((col:dashboard_title,opr:ct,value:#{title_contains}))," if title_contains.present?
      end

      def list_attributes
        [:id, :dashboard_title, :status, :url]
      end

      def rows
        result.map do |d|
          list_attributes.map do |la|
            la == :url ? "#{superset_host}#{d[la]}" : d[la]
          end
        end
      end
    end
  end
end