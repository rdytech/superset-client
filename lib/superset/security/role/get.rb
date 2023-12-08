module Superset
  module Security
    module Role
      class Get < Superset::Request
        attr_reader :id

        def initialize(id)
          @id = id
        end

        def result
          [ super ]
        end

        def id_and_name
          result.first.slice(:id, :name).values.join(': ')
        end

        private

        def list_attributes
          [:id, :name]
        end

        def route
          "security/roles/#{id}"
        end
      end
    end
  end
end

