module Superset
    module Database
      class Connection < Superset::Request
  
        attr_reader :id
  
        def initialize(id)
          @id = id
        end
  
        def self.call(id)
          self.new(id).result
        end
     
        def connection_db_name
          result['parameters']['database']
        end

        private
  
        def route
          "database/#{id}/connection"
        end
      end
    end
  end
  