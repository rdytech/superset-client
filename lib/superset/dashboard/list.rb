# Usage: Superset::Dashboard::List.new.list
# Usage: Superset::Dashboard::List.new(page_num: 1, title_contains: 'Test').list
# Usage: Superset::Dashboard::List.new(tags_equal: ['embedded', 'product:acme']).list

module Superset
  module Dashboard
    class List < Superset::Request

      attr_reader :title_contains, :title_equals,
                  :tags_contain, :tags_equal,
                  :ids_in, :ids_not_in,
                  :include_filter_dataset_schemas

      def initialize(page_num: 0, title_contains: '', title_equals: '',
                     tags_contain: [], tags_equal: [],
                     ids_in: [], ids_not_in: [],
                     include_filter_dataset_schemas: false)
        @title_contains = title_contains
        @title_equals = title_equals
        @tags_contain = tags_contain
        @tags_equal = tags_equal
        @ids_in = ids_in
        @ids_not_in = ids_not_in
        @include_filter_dataset_schemas = include_filter_dataset_schemas
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
        { schemas: Datasets::List.new(dashboard_id: id, include_filter_datasets: include_filter_dataset_schemas).schemas }
      rescue StandardError => e
        # within Superset, a bug exists around deleting dashboards failing and the corrupting datasets configs, so handle errored datasets gracefully
        # ref NEP-17532
        {}
      end

      def retrieve_embedded_details(id)
        embedded_dashboard = Dashboard::Embedded::Get.new(dashboard_id: id)
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

      def ids
        result.map { |d| d[:id] }
      end

      private

      def route
        "dashboard/?q=(#{query_params})"
      end

      def filters
        # TODO filtering across all list classes can be refactored to support multiple options in a more flexible way
        filter_set = []
        filter_set << "(col:dashboard_title,opr:ct,value:'#{title_contains}')" if title_contains.present?
        filter_set << "(col:dashboard_title,opr:eq,value:'#{title_equals}')" if title_equals.present?
        filter_set << tags_contain_filters if tags_contain.present?
        filter_set << tags_equal_filters if tags_equal.present?
        filter_set << ids_in_filters if ids_in.present?
        filter_set << ids_not_in_filters if ids_not_in.present?

        unless filter_set.empty?
          "filters:!(" + filter_set.join(',') + "),"
        end
      end

      def tags_equal_filters
        tags_equal_ids.map { |id| "(col:tags,opr:dashboard_tag_id,value:#{id})" }.join(',')
      end

      def tags_equal_ids
        tags_equal.map do |tag_name|
          ids = Superset::Tag::List.new(name_equals: tag_name).rows.map(&:first)
          raise "No ID found for tag: #{tag_name}" if ids.empty?
          raise "Multiple IDs found for tag: #{tag_name}" if ids.size > 1
          ids.first
        end
      end

      def tags_contain_filters
        tags_contain.map {|tag| "(col:tags,opr:dashboard_tags,value:'#{tag}')"}.join(',')
      end

      def ids_in_filters
        ids_in.map {|id| "(col:id,opr:eq,value:'#{id}')"}.join(',')
      end

      def ids_not_in_filters
        ids_not_in.map {|id| "(col:id,opr:neq,value:'#{id}')"}.join(',')

      def list_attributes
        [:id, :dashboard_title, :status, :url]
      end

      def validate_constructor_args
        raise InvalidParameterError, "title_contains must be a String type" unless title_contains.is_a?(String)
        raise InvalidParameterError, "title_equals must be a String type" unless title_equals.is_a?(String)
        raise InvalidParameterError, "tags_contain must be an Array type of String values" unless tags_contain.is_a?(Array) && tags_contain.all? { |item| item.is_a?(String) }
        raise InvalidParameterError, "tags_equal must be an Array type of String values" unless tags_equal.is_a?(Array) && tags_equal.all? { |item| item.is_a?(String) }
        raise InvalidParameterError, "ids_in must be an Array type" unless ids_in.is_a?(Array)
        raise InvalidParameterError, "ids_not_in must be an Array type" unless ids_not_in.is_a?(Array)
      end
    end
  end
end
