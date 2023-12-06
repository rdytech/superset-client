module Superset
  class Authenticator
    class CredentialMissingError < StandardError; end

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def self.call(credentials)
      self.new(credentials).access_token
    end

    def access_token
      response_body['access_token']
    end

    def refresh_token
      response_body['refresh_token']
    end

    def validate_credential_existance
      raise CredentialMissingError, 'password not set' unless credentials[:password].present?
      raise CredentialMissingError, 'username not set' unless credentials[:username].present?
    end

    def superset_host
      raise CredentialMissingError, "SUPERSET_HOST not found" unless ENV['SUPERSET_HOST'].present?

      ENV['SUPERSET_HOST']
    end

    private

    def response
      validate_credential_existance
      @response ||= connection.post(route,
                                    credentials.to_json,
                                    'Content-Type' => 'application/json')
    end

    def route
      'api/v1/security/login'
    end

    def response_body
      JSON.parse(response.env['body'] || response.env['response_body'])
    end

    def connection
      Faraday.new(superset_host)
    end
  end
end
