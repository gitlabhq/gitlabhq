# frozen_string_literal: true

require_relative 'db_cleaner'

RSpec.configure do |config|
  include DbCleaner

  # Ensure the database is empty at the start of the suite run with :deletion strategy
  # neither the sequence is reset nor the tables are vacuum, but this provides
  # better I/O performance on machines with slower storage
  config.before(:suite) do
    # We need to drop the partitions before the detached_partitions records are cleared below.
    # These detached partitions can cause flaky migration tests because these tables can have
    # foreign keys that would prevent the referenced table from being dropped.
    Gitlab::Database::Partitioning::DetachedPartitionDropper.new.drop_all_detached_partitions!

    setup_database_cleaner
    DatabaseCleaner.clean_with(:deletion)
  end
end
