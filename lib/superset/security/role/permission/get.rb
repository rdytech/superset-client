module Superset
  module Security
    module Role
      module Permission
        class Get < Superset::Request
          attr_reader :id

          def initialize(id)
            @id = id
          end

          def self.call(id)
            self.new(id)
          end

          def result
            response[:result]
          end

          private

          def list_attributes
            [:id, :permission_name, :view_menu_name]
          end

          def route
            "security/roles/#{id}/permissions/"
          end

          def title
            Superset::Security::Role::Get.new(id).id_and_name
          end
        end
      end
    end
  end
end
