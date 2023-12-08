module Superset
  module Security
    module User
      class List < Superset::Request
        attr_reader :page_num, :email_contains, :username_equals

        def initialize(page_num: 0, email_contains: '', username_equals: '')
          @page_num = page_num
          @email_contains = email_contains
          @username_equals = username_equals
        end

        def query_params
          [filters, pagination].join
        end

        private

        def route
          "security/users/?q=(#{query_params})"
        end

        def filters
          raise 'ERROR: only one filter supported currently' if  email_contains.present? && username_equals.present?

          if email_contains.present?
            "filters:!((col:email,opr:ct,value:#{email_contains})),"
          elsif username_equals.present?
            "filters:!((col:username,opr:eq,value:#{username_equals})),"
          else
            ''
          end
        end

        def title
          "#{response[:count]} Matching Users for Host: #{superset_host}\n" \
            "#{result.count} Users listed with: #{query_params}"
        end

        def list_attributes
          [:id, :first_name, :last_name, :email, :active, :login_count, :last_login]
        end
      end
    end
  end
end
