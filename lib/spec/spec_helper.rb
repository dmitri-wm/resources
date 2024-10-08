# frozen_string_literal: true

require 'resources'
require 'active_record'
require 'database_cleaner/active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
require 'test_prof/recipes/rspec/let_it_be'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
