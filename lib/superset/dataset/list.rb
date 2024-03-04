module Superset
  module Dataset
    class List < Superset::Request
      attr_reader :title_contains, :title_equals

      def initialize(page_num: 0, title_contains: '', title_equals: '')
        @title_contains = title_contains
        @title_equals = title_equals
        super(page_num: page_num)
      end

      def self.call
        self.new.list
      end

      private

      def route
        "dataset/?q=(#{query_params})"
      end

      def filters
        raise 'ERROR: only one filter supported currently' if  title_contains.present? && title_equals.present?

        return "filters:!((col:table_name,opr:ct,value:'#{title_contains}'))," if title_contains.present?
        return "filters:!((col:table_name,opr:eq,value:'#{title_equals}'))," if title_equals.present?
      end

      def list_attributes
        ['id', 'table_name', 'schema', 'changed_by_name']
      end
    end
  end
end
