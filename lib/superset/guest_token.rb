module Superset
  class GuestToken < Request
    include Credential::Embedded

    attr_accessor :ss_dashboard_id, :current_user

    def initialize(ss_dashboard_id, current_user: nil)
      @ss_dashboard_id = ss_dashboard_id
      @current_user = current_user
    end

    def guest_token
      response_body['token']
    end

    def params
      {
        "resources": [
          {
            "id": ss_dashboard_id.to_s,
            "type": "dashboard" }
        ],
        "rls": [],
        "user": current_user_params
      }
    end

    private

    # optional param to be available in Superset for query templating using jinja
    # ss expects username .. which we will use to query as current_user.id
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
      @connection ||= Faraday.new(superset_host) do |f|
        f.authorization :Bearer, access_token
        f.use FaradayMiddleware::ParseJson, content_type: 'application/json'
        f.request :json
        f.adapter :net_http
      end
    end

    def access_token
      @access_token ||= Superset::Authenticator.call(credentials)
    end
  end
end