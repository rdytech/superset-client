module Superset
  module Credential
    module Embedded

      private

      def credentials
        {
          "username": embedded_username,
          "password": embedded_password,
          "provider": "db",
          "refresh":  false
        }
      end

      def embedded_username
        ENV['SUPERSET_EMBEDDED_USERNAME']
      end

      def embedded_password
        ENV['SUPERSET_EMBEDDED_PASSWORD']
      end
    end
  end
end
