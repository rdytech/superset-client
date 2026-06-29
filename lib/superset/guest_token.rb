require 'faraday-cookie_jar'

module Superset
  class GuestToken
    include Credential::EmbeddedUser

    attr_accessor :embedded_dashboard_id, :rls_clause, :additional_params

    def initialize(embedded_dashboard_id:, rls_clause: [], **additional_params)
      @embedded_dashboard_id = embedded_dashboard_id
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
      current_user_id = additional_params[:embedded_app_current_user_id]
      if current_user_id
        { "username": current_user_id.to_s }
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

    # The guest_token endpoint is CSRF-protected (it is NOT in Superset's CSRF
    # exempt list), so this POST needs the same treatment as Client writes
    # (NEP-21211): an X-CSRFToken bound to the session cookie, plus a same-origin
    # Referer for WTF_CSRF_SSL_STRICT over HTTPS. The csrf_token GET also sets the
    # session cookie that the cookie jar replays on the POST.
    def response
      @response ||= begin
        connection.headers['X-CSRFToken'] = csrf_token
        connection.headers['Referer'] = authenticator.superset_host
        connection.post(route, params.to_json)
      end
    end

    def csrf_token
      @csrf_token ||= connection.get('api/v1/security/csrf_token/').env.body['result']
    end

    def connection
      @connection ||= Faraday.new(authenticator.superset_host) do |f|
        f.authorization :Bearer, access_token
        f.use :cookie_jar  # replay the Flask session cookie from the csrf_token GET on the POST
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
