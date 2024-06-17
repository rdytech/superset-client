module Superset
  class RouteInfo < Superset::Request
    alias result response

    attr_reader :route

    def initialize(route:)
      @route = route
    end

    def perform
      validate_route
      response
    end

    def response
      validate_route
      @response ||= client.get(route)
    end

    def filters
      result['filters']
    end

    private

    def validate_route
      unless route.present? && route.is_a?(String)
        puts "Example Route: 'dashboard/_info' "
        raise "Error: route string is required" unless route.present? && route.is_a?(String)
      end
    end
  end
end
