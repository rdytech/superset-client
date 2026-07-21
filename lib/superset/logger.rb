module Superset
  class Logger
    def info(msg)
      Superset.logger.info(msg)
    end

    def error(msg)
      Superset.logger.error(msg)
    end
  end
end
