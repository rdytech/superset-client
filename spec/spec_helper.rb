# frozen_string_literal: true

require 'pry'
require "faraday"
require "happi"
require "terminal-table"
require "rollbar"
require "superset/credential/api_user"
require "superset/credential/embedded_user"
require "superset/client"
require "superset/display"
require "superset/request"

Dir["./lib/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
