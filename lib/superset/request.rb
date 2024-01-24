module Superset
  class Request
    include Display

    class InvalidParameterError < StandardError; end

    PAGE_SIZE = 100

    attr_accessor :page_num

    def initialize(page_num: 0)
      @page_num = page_num
    end

    def self.call
      self.new.response
    end

    def response
      @response ||= client.get(route)
    end

    def result
      response['result']
    end

    def superset_host
      client.superset_host
    end

    def query_params
      [filters, pagination].join
    end

    private

    def route
      raise NotImplementedError.new("You must implement route.")
    end

    def client
      @client ||= Superset::Client.new
    end

    def pagination
      "page:#{page_num},page_size:#{PAGE_SIZE}"
    end

    def filters
      ""
    end
  end
end
