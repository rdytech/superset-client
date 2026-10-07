require "logger"

module Superset
  class Configuration
    attr_accessor :logger

    def initialize
      @logger = nil
    end
  end
end
