module Superset
  class Request
    include Display

    class InvalidParameterError < StandardError; end
    class ValidationError < StandardError; end

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
      [filters, pagination, order_by].join
    end

    def order_by
      # by default, we will order by changed_on as per the GUI
      ",order_column:changed_on,order_direction:desc"
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
      "page:#{page_num},page_size:#{PAGE_SIZE}"
    end

    def filters
      ""
    end

    def logger
      @logger ||= Superset::Logger.new
    end
  end
end
