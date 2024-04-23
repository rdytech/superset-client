module Superset
  module Tag
    class List < Superset::Request
      attr_reader :name_contains, :name_equals

      def initialize(page_num: 0, name_contains: '', name_equals: '')
        @name_contains = name_contains
        @name_equals = name_equals
        super(page_num: page_num)
      end

      def self.call
        self.new.list
      end

      private

      def route
        "tag/?q=(#{query_params})"
      end

      def filters
        # TODO filtering across all list classes can be refactored to support multiple options in a more flexible way
        filter_set = []
        filter_set << "(col:name,opr:ct,value:'#{name_contains}')" if name_contains.present?
        filter_set << "(col:name,opr:eq,value:#{name_equals})" if name_equals.present?  
        unless filter_set.empty?
          "filters:!(" + filter_set.join(',') + "),"
        end
      end

      def list_attributes
        ['id', 'name', 'description']
      end
    end
  end
end