module Superset
  module Dashboard
    module Embedded
      class Put < Superset::Request
        attr_reader :dashboard_id, :embedded_domain

        def initialize(dashboard_id: , embedded_domain: )
          @dashboard_id = dashboard_id
          @embedded_domain = embedded_domain
        end

        def response
          @response ||= client.put(route, params)
        end

        def params
          { "allowed_domains": [embedded_domain] }
        end

        def uuid
          result['uuid'] unless response[:result].empty?
        end

        private

        def route
          "dashboard/#{dashboard_id}/embedded"
        end
      end
    end
  end
end
