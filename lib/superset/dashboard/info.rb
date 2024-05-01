module Superset
  module Dashboard
    class Info < Superset::Request
      alias result response

      def filters
        result['filters']
      end

      private

      def route
        "dashboard/_info"
      end
    end
  end
end