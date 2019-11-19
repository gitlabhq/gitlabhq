# frozen_string_literal: true

require_relative 'db_cleaner'

RSpec.configure do |config|
  include DbCleaner

  # Ensure all sequences are reset at the start of the suite run
  config.before(:suite) do
    setup_database_cleaner
    DatabaseCleaner.clean_with(:truncation)
  end

  config.append_after(:context) do
    delete_from_all_tables!
  end

  config.around(:each, :delete) do |example|
    self.class.use_transactional_tests = false

    example.run

    delete_from_all_tables!(except: deletion_except_tables)
  end

  config.around(:each, :migration) do |example|
    self.class.use_transactional_tests = false

    example.run

    delete_from_all_tables!
  end
end
