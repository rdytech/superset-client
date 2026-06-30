require 'faraday-cookie_jar'

module Superset
  class Client < Happi::Client
    include Credential::ApiUser

    # Superset enforces CSRF on state-changing requests once WTF_CSRF_ENABLED is on;
    # GETs are never CSRF-checked. Bearer-token auth is not sufficient,
    # so these verbs must carry an X-CSRFToken header (see #call / #csrf_token).
    CSRF_PROTECTED_METHODS = %i[post put patch delete].freeze

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

    # All verbs funnel through Happi::Client#call. Before any state-changing request,
    # attach a CSRF token; fetching one also sets the Flask session cookie that the
    # token is validated against, which the cookie jar on this connection replays on
    # the write.
    def call(method, url, params = {})
      set_csrf_token if CSRF_PROTECTED_METHODS.include?(method)
      super
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
      # binding.pry                 # helpfull to debug the response

      raise errors[response.status].new(message, response)  # message is not being surfaced from Happi correctly, :(
    end

    private

    # Set the CSRF headers for the upcoming write:
    #   * X-CSRFToken — session-bound token; GET /api/v1/security/csrf_token/ returns it
    #     and sets the Flask session cookie it is validated against (the cookie jar on
    #     this connection replays that cookie on the write).
    #   * Referer — over HTTPS, Flask-WTF's WTF_CSRF_SSL_STRICT (default True) also
    #     requires a Referer matching the Superset host (same-origin check), else the
    #     write fails with "400 The referrer header is missing." Browsers send this
    #     automatically; an API client must set it explicitly.
    def set_csrf_token
      connection.headers['X-CSRFToken'] = csrf_token
      connection.headers['Referer'] = superset_host
    end

    def csrf_token
      @csrf_token ||= get('security/csrf_token/')['result']
    end

    def connection
      @connection ||= Faraday.new(superset_host) do |f|
        f.authorization :Bearer, access_token
        f.use :cookie_jar  # persist the Flask session cookie across the csrf_token GET and the write
        f.use FaradayMiddleware::ParseJson, content_type: 'application/json'

        if self.config.use_json
          f.request :json
        else
          f.request :multipart
          f.request :url_encoded
        end

        f.adapter :net_http
      end
    end
  end
end
