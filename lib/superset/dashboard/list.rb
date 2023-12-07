module Superset
  module Dashboard
    class List < Superset::Request

      def self.call
        self.new.list
      end

      def all
        result.map do |d|
          OpenStruct.new(
            list_attributes.map { |la| [la, d[la]] }.to_h.
              merge(retrieve_schemas(d[:id])).
              merge(retrieve_embedded_details(d[:id]))
            )
        end
      end

# Coming soon ... requires other classes to be implemented first.      
#      # TODO: currently in SS v2.1 there is no way to get a list of all dashboards schemas easily
#      # so we have to make a separate request for each dashboard to retrieve any associated datasets schemas.
#      # UPCOMING: now in SS v3, we will be able to filter by TAGs as well. So potentially we can tag each dashboard with the client schema name.
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
        "dashboard/"
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
