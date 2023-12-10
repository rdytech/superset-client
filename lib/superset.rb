# frozen_string_literal: true

require_all "lib/superset/credential"
require_relative "superset/authenticator"
require_relative "superset/client"
require_relative "superset/display"
require_relative "superset/request"
require_all 'lib'

module Superset
  class Error < StandardError; end
  # Your code goes here...
end
