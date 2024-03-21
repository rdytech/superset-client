module Superset
  class Logger
    
    def info(msg)
      logger.info(msg)
    end

    def error(msg)
      logger.error(msg)
    end

    def logger
      @logger ||= begin
        ::Logger.new("log/superset-client.log")
      end
    end
  end
end