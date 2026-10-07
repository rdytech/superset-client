# frozen_string_literal: true

require 'pry'

# Load the gem exactly as a consumer does, through its own entry point.
#
# This used to require the gem's dependencies here (happi, enumerate_it, faraday,
# terminal-table) and then glob `Dir["./lib/**/*.rb"]`. Both hid real bugs: the
# suite supplied requires that lib/ was missing, and it never loaded lib/superset.rb
# at all. 0.5.3 shipped unloadable — `uninitialized constant EnumerateIt` — with the
# whole suite green. Nothing may be required here that the gem should require itself.
require "superset"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
