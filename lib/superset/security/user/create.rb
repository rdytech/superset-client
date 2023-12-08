module Superset
  module Security
    module User
      class Create < Superset::Request
        attr_reader :role_id

        def initialize(role_id)
          @role_id = role_id
        end

        def response
          raise InvalidParameterError unless role_id.present?

          @response ||= client.post(route, params)
        end

        def params
          {
            "active": true,
            "email": "#{identifier}@ewp.readytech.io",
            "first_name": "Jobready Application",
            "last_name": identifier,
            "password": password,
            "roles": [ role_id ],
            "username": identifier
          }
        end

        def identifier
          # example:  jobready_atwork_stage_embedded_user
          ['jobready', current_tenant.database, 'embedded_user'].join('_')
        end

        private

        def password
          @password ||= SecureRandom.urlsafe_base64(32)
        end

        def route
          "security/users/"
        end
      end
    end
  end
end
