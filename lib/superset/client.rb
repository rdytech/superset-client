module Superset
  class Client < Happi::Client
    include Credential::ApiUser

    attr_reader :authenticator

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

    # TODO: Happi has not got a put method yet
    def put(resource, params = {})
      call(:put, url(resource), param_check(params))
        .body.with_indifferent_access
    end

    # TODO: Happi is not surfacing the errors correctly overriding raise_error for now
    def raise_error(response)
      message =
      if response.body['errors']
        response.body['errors']
      else
        response.body
      end

      puts "API Error: #{message}"  # display the error message for console debugging
      binding.pry                 # helpfull to debug the response

      raise errors[response.status].new(message, response)  # message is not being surfaced from Happi correctly, :(
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
