# frozen_string_literal: true

ENV["resources_env"] = "test"

require "factory_bot"
require "faker"
require "database_cleaner/active_record"
require "resources"

RSpec.configure do |config|
  FactoryBot.find_definitions

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.include FactoryBot::Syntax::Methods

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
