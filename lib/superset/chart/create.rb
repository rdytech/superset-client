=begin
Create a new chart from a set of params
Suggestion is to base your params of an existing charts params and then modify them as needed
So .. why not call the Superset::Chart::Duplicate class which then calls this Chart::Create class

This class is a bit more generic and can be used to create a new chart from scratch (if your confident in the params)

Usage: 
Superset::Chart::Create.new(params: new_chart_params).perform
=end

module Superset
  module Chart
    class Create < Superset::Request

      attr_reader :params

      def initialize(params: )
        @params = params
      end

      def perform
        raise "Error: params hash is required" unless params.present? && params.is_a?(Hash)

        logger.info("Creating New Chart")
        response['id']
      end

      def response
        @response ||= client.post(route, params)
      end

      private

      def route
        "chart/"
      end
    end
  end
end
