# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "resources"
  spec.version = 1
  spec.authors = ["dmitri-wm"]
  spec.email = ["dmytro.kyselevych-contractor@procore.com"]

  spec.summary = "A flexible ORM-like tool for mapping data between various data sources"
  spec.description = "Resources is an internal ORM-like tool built on top of Active Record for SQL queries. It provides a flexible and scalable approach to map data between different types of data sources such as databases, HTTP APIs, arrays, in-memory databases, and more."
  spec.homepage = "https://github.com/your-organization/resources" # Update this with your actual repo URL
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://your-private-gem-server.com" # Update this if you have a private gem server

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = %w[lib]

  # Dependencies
  spec.add_dependency "dry-matcher"
  spec.add_dependency "dry-monads"
  spec.add_dependency "dry-struct"
  spec.add_dependency "dry-validation"

  # Development dependencies
  spec.add_development_dependency "activerecord", "~> 7.0.8.1"
  spec.add_development_dependency "pg", "~> 1.3.5"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
