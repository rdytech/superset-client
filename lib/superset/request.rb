module Superset
  class Request
    include Display

    class InvalidParameterError < StandardError; end

    PAGE_SIZE = 100

    attr_accessor :client

    def self.call
      self.new.response
    end

    def response
      @response ||= client.get(route)
    end

    def result
      response['result']
    end

    def superset_host
      client.superset_host
    end

    private

    def route
      raise NotImplementedError.new("You must implement route.")
    end

    def client
      @client ||= Superset::Client.new
    end

    def security_api_request?
      false
    end

# Seeing what breaks .. ie we will need to pull out any refs to current_tenant
#    def current_tenant
#      @current_tenant ||= Tenant.current
#    end

    def pagination
      "page:#{page_num},page_size:#{PAGE_SIZE}"
    end
  end
end
