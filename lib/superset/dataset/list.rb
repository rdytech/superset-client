module Superset
  module Dataset
    class List < Superset::Request
      attr_reader :title_contains, :title_equals, :schema_equals

      def initialize(page_num: 0, title_contains: '', title_equals: '', schema_equals: '')
        @title_contains = title_contains
        @title_equals = title_equals
        @schema_equals = schema_equals
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
        # TODO filtering across all list classes can be refactored to support multiple options in a more flexible way
        filters = []
        filters << "(col:table_name,opr:ct,value:'#{title_contains}')" if title_contains.present?
        filters << "(col:table_name,opr:eq,value:'#{title_equals}')" if title_equals.present?
        filters << "(col:schema,opr:eq,value:'#{schema_equals}')" if schema_equals.present?
        unless filters.empty?
          "filters:!(" + filters.join(',') + "),"
        end
      end

      def list_attributes
        ['id', 'table_name', 'schema', 'changed_by_name']
      end
    end
  end
end
