module Superset
  class Client < Happi::Client
    include Credential::ApiUser

    attr_reader :authenticator
    attr_accessor :connection

    def initialize
      @authenticator = Superset::Authenticator.new(credentials)
      super(log_level: :debug, host: superset_host)
    end

    def access_token
      @access_token ||= authenticator.access_token
    end

    def superset_host
      @superset_host ||= authenticator.superset_host
    end

    private

    def connection
      @connection ||= Faraday.new(superset_host) do |f|
        f.authorization :Bearer, access_token
        f.use FaradayMiddleware::ParseJson, content_type: 'application/json'
        f.request :json

        f.adapter :net_http
      end
    end
  end
end