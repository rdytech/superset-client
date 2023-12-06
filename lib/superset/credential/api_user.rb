module Superset
  module Credential
    module ApiUser

      def credentials
        {
          "username": api_username,
          "password": api_password,
          "provider": "db",
          "refresh":  false
        }
      end

      private

      def api_username
        ENV['SUPERSET_API_USERNAME']
      end

      def api_password
        ENV['SUPERSET_API_PASSWORD']
      end
    end
  end
end
