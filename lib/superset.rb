# frozen_string_literal: true

require 'require_all'

require_rel "superset/credential"
require_relative "superset/authenticator"
require_relative "superset/client"
require_relative "superset/display"
require_relative "superset/logger"
require_relative "superset/request"

require_rel "superset"

module Superset
  class Error < StandardError; end
  # Your code goes here...
end
