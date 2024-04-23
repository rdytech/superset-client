module Superset
  class Logger
    
    def info(msg)
      # puts msg   # allow logs to console
      logger.info msg
    end

    def error(msg)
      # puts msg   # allow logs to console
      logger.error msg
    end

    def logger
      @logger ||= begin
        ::Logger.new("log/superset-client.log")
      end
    end
  end
end