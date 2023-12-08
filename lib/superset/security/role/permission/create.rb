module Superset
  module Security
    module Role
      module Permission
        class Create < Superset::Request
          attr_reader :role_id, :permission_view_menu_ids

          def initialize(role_id:, permission_view_menu_ids: [])
            @permission_view_menu_ids = permission_view_menu_ids
            @role_id = role_id
          end

          def response
            raise InvalidParameterError unless valid_params?

            @response ||= client.post(route,
                                      { "permission_view_menu_ids": permission_view_menu_ids } )
          end

          private

          def valid_params?
            role_id.present? &&
              permission_view_menu_ids.is_a?(Array) &&
              !permission_view_menu_ids.empty?
          end

          def route
            "security/roles/#{role_id}/permissions"
          end
        end
      end
    end
  end
end
