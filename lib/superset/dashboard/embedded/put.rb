module Superset
  module Dashboard
    module Embedded
      class Put < Superset::Request
        attr_reader :dashboard_id, :allowed_domains

        def initialize(dashboard_id: , allowed_domains: )
          @dashboard_id = dashboard_id
          @allowed_domains = allowed_domains
        end

        def response
          raise  InvalidParameterError, 'dashboard_id integer is required' if dashboard_id.nil? || dashboard_id.class != Integer
          raise  InvalidParameterError, 'allowed_domains array is required' if allowed_domains.nil? || allowed_domains.class != Array

          @response ||= client.put(route, params)
        end

        def params
          { "allowed_domains": allowed_domains }
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
