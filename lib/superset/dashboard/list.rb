module Superset
  module Dashboard
    class List < Superset::Request
      attr_reader :title_contains, :tag_equals

      def initialize(page_num: 0, title_contains: '', tag_equals: '')
        @title_contains = title_contains
        @tag_equals = tag_equals
        super(page_num: page_num)
      end

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

      def retrieve_schemas(id)
        { schemas: Datasets::List.new(id).schemas }
      rescue StandardError => e
        # within Superset, a bug exists around deleting dashboards failing and the corrupting datasets configs, so handle errored datasets gracefully
        # ref NEP-17532
        {}
      end

      def retrieve_embedded_details(id)
        embedded_dashboard = Dashboard::Embedded::Get.new(id)
        { allowed_embedded_domains: embedded_dashboard.allowed_domains,
          uuid: embedded_dashboard.uuid,}
      end

      def rows
        result.map do |d|
          list_attributes.map do |la|
            la == :url ? "#{superset_host}#{d[la]}" : d[la]
          end
        end
      end

      private

      def route
        "dashboard/?q=(#{query_params})"
      end

      def filters
        # TODO filtering across all list classes can be refactored to support multiple options in a more flexible way
        filter_set = []
        filter_set << "(col:dashboard_title,opr:ct,value:'#{title_contains}')" if title_contains.present?
        filter_set << "(col:tags,opr:dashboard_tags,value:#{tag_equals})" if tag_equals.present?  
        unless filter_set.empty?
          "filters:!(" + filter_set.join(',') + "),"
        end
      end

      def list_attributes
        [:id, :dashboard_title, :status, :url]
      end
    end
  end
end