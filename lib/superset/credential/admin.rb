module Superset
  module Credential
    module Admin

      private

      def credentials
        {
          "username": admin_username,
          "password": admin_password,
          "provider": "db",
          "refresh":  false
        }
      end

      def admin_username
        ENV['SUPERSET_API_USERNAME']
      end

      def admin_password
        ENV['SUPERSET_API_PASSWORD']
      end
    end
  end
end
