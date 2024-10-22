

module Superset
  class BasePutRequest < Superset::Request
    attr_reader :object_id, :params

    def initialize(object_id: ,params: )
      @object_id = object_id
      @params = params
    end

    def perform
      validate
      response
    end

    def response
      @response ||= client.put(route, params)
    end

    private

    def validate
      raise "Error: object_id integer is required" unless object_id.present? && object_id.is_a?(Integer)
      raise "Error: params hash is required" unless params.present? && params.is_a?(Hash)
    end

    def route
      raise "Error: route method is required"
    end
  end
end
