module Superset
  module Security
    module PermissionsResources
      class List < Superset::Request

        def initialize(page_num: 0)         
          super(page_num: page_num)
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
