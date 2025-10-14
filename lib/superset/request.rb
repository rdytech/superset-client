module Superset
  class Request
    include Display

    class InvalidParameterError < StandardError; end
    class ValidationError < StandardError; end

    DEFAULT_PAGE_SIZE = 100

    attr_accessor :page_num, :page_size

    def initialize(page_num: 0, page_size: nil)
      @page_num = page_num
      @page_size = page_size || DEFAULT_PAGE_SIZE
    end

    def self.call
      self.new.response
    end

    def response
      @response ||= client.get(route)
    rescue => e
      logger.error("#{e.message}")
      raise e
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

    def client(use_json: true)
      @client ||= begin
        c = Superset::Client.new
        c.config.use_json = use_json
        c
      end
    end

    def pagination
      raise InvalidParameterError, "page_size max is 1000 records" if page_size.to_i > 1000
      "page:#{page_num},page_size:#{page_size}"
    end

    def filters
      ""
    end

    def logger
      @logger ||= Superset::Logger.new
    end
  end
end
