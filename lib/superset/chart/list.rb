module Superset
  module Chart
    class List < Superset::Request

      attr_reader :name_contains

      def initialize(page_num: 0, name_contains: '')
        @name_contains = name_contains
        super(page_num: page_num)
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
        "filters:!((col:slice_name,opr:ct,value:#{name_contains}))," if name_contains.present?
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