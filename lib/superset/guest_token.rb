module Superset
  class GuestToken
    include Credential::EmbeddedUser

    attr_accessor :embedded_dashboard_id, :current_user, :rls_clause, :additional_params

    def initialize(embedded_dashboard_id: , current_user: nil, rls_clause: [], **additional_params)
      @embedded_dashboard_id = embedded_dashboard_id
      @current_user = current_user
      @rls_clause = rls_clause
      @additional_params = additional_params
    end

    def guest_token
      validate_params
      response_body['token']
    end

    def params
      {
        "resources": [
          {
            "id": embedded_dashboard_id.to_s,
            "type": "dashboard" }
        ],
        "rls": rls_clause, # Ex: [{ "clause": "publisher = 'Nintendo'" }]
        "user": current_user_params
      }.merge(additional_params)
    end

    private

    def validate_params
      raise Superset::Request::InvalidParameterError, "rls_clause should be an array. But it is #{rls_clause.class}" if rls_clause.nil? || rls_clause.class != Array
    end

    # optional param to be available in Superset for query templating using jinja
    # ss expects username .. which could be used to query as current_user.id
    def current_user_params
      if current_user
        { "username": current_user.id.to_s }
      else
        { }
      end
    end

    def response_body
      response.env.body
    end

    def route
      'api/v1/security/guest_token/'
    end

    def response
      @response ||= connection.post(route, params.to_json)
    end

    def connection
      @connection ||= Faraday.new(authenticator.superset_host) do |f|
        f.authorization :Bearer, access_token
        f.use FaradayMiddleware::ParseJson, content_type: 'application/json'
        f.request :json
        f.adapter :net_http
      end
    end

    def access_token
      @access_token ||= authenticator.access_token
    end

    def authenticator
      @authenticator ||= Superset::Authenticator.new(credentials)
    end
  end
end
