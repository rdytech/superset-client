module Superset
  module Security
    module User
      class Get < Superset::Request
        attr_reader :id

        def initialize(id)
          @id = id
        end

        def result
          [ super ]
        end

        private

        def list_attributes
          [:id, :first_name, :last_name, :email, :login_count, :last_login]
        end

        def route
          "security/users/#{id}"
        end
      end
    end
  end
end
