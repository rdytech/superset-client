# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in superset.gemspec
gemspec

# Pinned to the version consumers actually run. happi <= 0.6.0 pulled in
# faraday_middleware, which silently supplied FaradayMiddleware::ParseJson to this
# gem's connections and hid the fact that it was never a declared dependency here.
gem 'happi', git: 'https://github.com/rdytech/happi.git', tag: 'v1.0.0'

