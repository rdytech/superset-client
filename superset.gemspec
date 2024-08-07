# frozen_string_literal: true

require_relative "lib/superset/version"

Gem::Specification.new do |spec|
  spec.name = "superset"
  spec.version = Superset::VERSION
  spec.authors = ["jbat"]
  spec.email = ["jonathon.batson@gmail.com"]

  spec.summary = "A Ruby Client for Apache Superset API"
  spec.homepage = "https://github.com/rdytech/superset-client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  #spec.metadata["allowed_push_host"] = ""

  #spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = ""
  #spec.metadata["changelog_uri"] = ""

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  #spec.bindir = "exe"
  #spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = [
    "lib"
  ]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "dotenv", "~> 2.7"
  spec.add_dependency "json", "~> 2.6"
  spec.add_dependency "terminal-table", "~> 1.8"
  spec.add_dependency "rake", "~> 13.0"
  spec.add_dependency "rollbar", "~> 3.4"
  spec.add_dependency "require_all", "~> 3.0"
  spec.add_dependency "rubyzip", "~> 1.0"
  spec.add_dependency "faraday", "~> 1.0"
  spec.add_dependency "faraday-multipart", "~> 1.0"
  spec.add_dependency "enumerate_it", "~> 1.7.0"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.5"
  spec.add_development_dependency "pry", "~> 0.14"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
