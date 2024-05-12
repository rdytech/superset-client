# Usage: Superset::Database::List.call
# Usage: Superset::Dashboard::List.new(title_contains: 'test').list

module Superset
  module Database
    class List < Superset::Request
      attr_reader :title_contains

      def initialize(page_num: 0, title_contains: '')
        @title_contains = title_contains
        super(page_num: page_num)
      end

      def self.call
        self.new.list
      end

      def response
        validate_constructor_args
        super
      end

      def ids
        result.map { |d| d[:id] }
      end

      private

      def route
        "database/?q=(#{query_params})"
      end

      def filters
        # TODO filtering across all list classes can be refactored to support multiple options in a more flexible way
        filter_set = []
        filter_set << "(col:database_name,opr:ct,value:'#{title_contains}')" if title_contains.present?
        unless filter_set.empty?
          "filters:!(" + filter_set.join(',') + "),"
        end
      end

      def list_attributes
        [:id, :database_name, :backend, :expose_in_sqllab]
      end

      def validate_constructor_args
        raise InvalidParameterError, "title_contains must be a String type" unless title_contains.is_a?(String)
      end
    end
  end
end
