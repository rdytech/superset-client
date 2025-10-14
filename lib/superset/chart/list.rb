module Superset
  module Chart
    class List < Superset::Request

      attr_reader :name_contains, :dashboard_id_eq, :dataset_id_eq

      def initialize(name_contains: '', dashboard_id_eq: '', dataset_id_eq: '', **kwargs)
        @name_contains = name_contains
        @dashboard_id_eq = dashboard_id_eq
        @dataset_id_eq = dataset_id_eq
        super(**kwargs)
      end

      def self.call
        self.new.list
      end

      def list_with_dashboards
        puts Terminal::Table.new(
          title: title,
          headings: list_dashboard_attributes.map(&:to_s).map(&:humanize),
          rows: rows_with_dashboards
        )
      end

      def rows_with_dashboards
        result.map do |d|
          list_dashboard_attributes.map { |la| d[la].to_s }
        end
      end

      private

      def route
        "chart/?q=(#{query_params})"
      end

      def filters
        # TODO filtering across all classes needs a refactor to support multiple options in a more flexible way
        filter_set = []
        filter_set << "(col:slice_name,opr:ct,value:'#{name_contains}')" if name_contains.present?
        filter_set << "(col:dashboards,opr:rel_m_m,value:#{dashboard_id_eq})" if dashboard_id_eq.present? # rel many to many
        filter_set << "(col:datasource_id,opr:eq,value:#{dataset_id_eq})" if dataset_id_eq.present?

        unless filter_set.empty?
          "filters:!(" + filter_set.join(',') + "),"
        end
      end

      def list_attributes
        ['id', 'slice_name', 'datasource_id', 'datasource_name_text', 'created_by_name']
      end

      def list_dashboard_attributes
        ['id', 'slice_name', 'dashboards']
      end
    end
  end
end
