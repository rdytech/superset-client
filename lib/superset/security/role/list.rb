module Superset
  module Security
    module Role
      class List < Superset::Request
        attr_reader :page_num, :name_contains, :name_equals

        def initialize(page_num: 0, name_contains: nil, name_equals: nil)
          @page_num = page_num
          @name_contains= name_contains
          @name_equals= name_equals
        end

        def self.call
          self.new.list
        end

        private

        def route
          "security/roles/?q=(#{query_params})"
        end

        def filters
          raise 'ERROR: only one filter supported currently' if  name_contains.present? && name_equals.present?

          if name_contains.present?
            "filters:!((col:name,opr:ct,value:'#{name_contains}')),"
          elsif name_equals.present?
            "filters:!((col:name,opr:eq,value:'#{name_equals}')),"
          else
            ''
          end
        end

        def title
          "#{response[:count]} Roles for Host: #{superset_host}"
        end

        def list_attributes
          [:id, :name]
        end
      end
    end
  end
end
