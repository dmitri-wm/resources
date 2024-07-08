# frozen_string_literal: true

require "active_record"
ActiveRecord::Base.establish_connection("postgresql://procore_db:postgres@localhost:5432/resources_test")
require "factory_bot"
require "faker"
require_relative "../lib/external/models/change_event"
require_relative "../lib/external/models/change_event_line_item"
require_relative "../lib/external/models/line_item"
require_relative "../lib/external/models/potential_change_order"
require_relative "../lib/external/models/contract"
require_relative "factories/change_event_line_item_factory"
require "resources"
require "database_cleaner/active_record"

RSpec.configure do |config|
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
