module Superset
  class BasePutRequest < Superset::Request
    attr_reader :target_id, :params

    def initialize(target_id: ,params: )
      @target_id = target_id
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
      raise "Error: target_id integer is required" unless target_id.present? && target_id.is_a?(Integer)
      raise "Error: params hash is required" unless params.present? && params.is_a?(Hash)
    end

    def route
      raise "Error: route method is required"
    end
  end
end
