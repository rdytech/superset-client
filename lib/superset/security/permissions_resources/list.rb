module Superset
  module Security
    module PermissionsResources
      class List < Superset::Request

        def initialize(**kwargs)
          super(**kwargs)
        end

        private

        def list_attributes
          [:id, :permission, :view_menu]
        end

        def route
          "security/permissions-resources/?q=(#{pagination})"
        end
      end
    end
  end
end
