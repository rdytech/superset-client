# frozen_string_literal: true

require 'require_all'
require 'terminal-table'
require 'happi'
require 'logger'

require_relative "superset/configuration"
require_rel "superset/credential"
require_relative "superset/authenticator"
require_relative "superset/client"
require_relative "superset/display"
require_relative "superset/logger"
require_relative "superset/request"

require_rel "superset"

module Superset
  class Error < StandardError; end

  DEFAULT_LOG_PATH = "log/superset-client.log"

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def logger
      configuration.logger || default_logger
    end

    def reset_configuration!
      @configuration = nil
      @default_logger = nil
    end

    private

    def default_logger
      @default_logger ||= ::Logger.new(DEFAULT_LOG_PATH)
    end
  end
end
