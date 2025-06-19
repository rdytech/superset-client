# Superset has a 100 result limit for requests
# This is a wrapper for Superset::Dashboard::List to recursively list all dashboards 

# TODO - would be very handy to create a parent class for this
#        to then be able to use the same pattern for other ::List classes

module Superset
  module Dashboard
    class ListAll
      include Display

      def initialize(**kwargs)
        kwargs.each do |key, value|
          instance_variable_set("@#{key}", value)
          self.class.attr_reader key
        end
      end

      def constructor_args
        instance_variables.each_with_object({}) do |var, hash|
          hash[var.to_s.delete('@').to_sym] = instance_variable_get(var)
        end
      end
      
      def perform
        page_num = 0
        boards = []
        boards << next_group = Dashboard::List.new(page_num: page_num, **constructor_args).result
        while !next_group.empty?
          boards << next_group = Dashboard::List.new(page_num: page_num += 1, **constructor_args).result
        end
        @result = boards.flatten
      end

      def result
        @result ||= []
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

      def list_attributes
        [:id, :dashboard_title, :status, :url]
      end

      def superset_host
        ENV['SUPERSET_HOST']
      end
    end
  end
end
