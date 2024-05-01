module Superset
  module Dashboard
    module Embedded
      class Get < Superset::Request
        attr_reader :id  # dashboard id

        def self.call(id)
          self.new(id).list
        end

        def initialize(id)
          @id = id
        end

        def response
          @response ||= client.get(route)
        rescue Happi::Error::NotFound => e
          logger.info("Dashboard #{id} has no Embedded settings. (skipping)") # some dashboards don't have embedded settings, fine to ignore.
          @response = { result: [] }.with_indifferent_access
          @response
        end

        def result
          response[:result].empty? ? [] : [ super ] # wrap single result in an array so it can be used in the tt list and table
        end

        def allowed_domains
          result.first['allowed_domains'] unless response[:result].empty?
        end

        def uuid
          result.first['uuid'] unless response[:result].empty?
        end

        def list
          super unless response[:result].empty?
        end

        private

        def route
          "dashboard/#{id}/embedded"
        end

        def list_attributes
          [:dashboard_id, :uuid, :allowed_domains, :changed_on]
        end

        # when displaying embedded details, show dashboard title as well
        def title
          Superset::Dashboard::Get.new(id).title
        end
      end
    end
  end
end
