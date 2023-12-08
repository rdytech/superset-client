module Superset
  module Security
    module Role
      class Create < Superset::Request
        attr_reader :name

        def initialize(name: '')
          @name = name
        end

        def response
          raise InvalidParameterError unless name.present?

          @response ||= client.post(route, { 'name' => name } )
        end

        private

        def route
          "security/roles/"
        end
      end
    end
  end
end
