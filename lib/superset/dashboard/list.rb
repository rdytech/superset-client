# Usage: Superset::Dashboard::List.new.list
# Usage: Superset::Dashboard::List.new(page_num: 1, title_contains: 'Test').list
# Usage: Superset::Dashboard::List.new(tags_equal: ['embedded', 'product:acme']).list

module Superset
  module Dashboard
    class List < Superset::Request
      attr_reader :title_contains, :tags_equal, :ids_not_in

      def initialize(page_num: 0, title_contains: '', tags_equal: [], ids_not_in: [])
        @title_contains = title_contains
        @tags_equal = tags_equal
        @ids_not_in = ids_not_in
        super(page_num: page_num)
      end

      def self.call
        self.new.list
      end

      def response
        validate_constructor_args
        super
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
        filter_set << tag_filters if tags_equal.present?
        filter_set << ids_not_in_filters if ids_not_in.present?
        unless filter_set.empty?
          "filters:!(" + filter_set.join(',') + "),"
        end
      end

      def tag_filters
        tags_equal.map {|tag| "(col:tags,opr:dashboard_tags,value:'#{tag}')"}.join(',')
      end

      def ids_not_in_filters
        ids_not_in.map {|id| "(col:id,opr:neq,value:'#{id}')"}.join(',')
      end

      def list_attributes
        [:id, :dashboard_title, :status, :url]
      end

      def validate_constructor_args
        raise InvalidParameterError, "title_contains must be a String type" unless title_contains.is_a?(String)
        raise InvalidParameterError, "tags_equal must be an Array type" unless tags_equal.is_a?(Array)
        raise InvalidParameterError, "tags_equal array must contin string only values" unless tags_equal.all? { |item| item.is_a?(String) }
        raise InvalidParameterError, "ids_not_in must be an Array type" unless ids_not_in.is_a?(Array)
      end
    end
  end
end
