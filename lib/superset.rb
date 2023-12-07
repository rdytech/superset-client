# frozen_string_literal: true

require_relative "superset/version"
require_relative "superset/credential/api_user"
require_relative "superset/credential/embedded_user"
require_relative "superset/authenticator"
require_relative "superset/client"
require_relative "superset/display"
require_relative "superset/request"
require_relative "superset/dashboard/list"

module Superset
  class Error < StandardError; end
  # Your code goes here...
end
