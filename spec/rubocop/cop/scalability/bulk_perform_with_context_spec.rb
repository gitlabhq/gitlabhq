# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/scalability/bulk_perform_with_context'

RSpec.describe RuboCop::Cop::Scalability::BulkPerformWithContext do
  it "adds an offense when calling bulk_perform_async" do
    expect_offense(<<~RUBY)
      Worker.bulk_perform_async(args)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer using `Worker.bulk_perform_async_with_contexts` [...]
    RUBY
  end

  it "adds an offense when calling bulk_perform_in" do
    expect_offense(<<~RUBY)
      diffs.each_batch(of: BATCH_SIZE) do |relation, index|
        ids = relation.pluck_primary_key.map { |id| [id] }
        DeleteDiffFilesWorker.bulk_perform_in(index * 5.minutes, ids)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer using `Worker.bulk_perform_async_with_contexts` [...]
      end
    RUBY
  end

  it "does not add an offense for migrations" do
    allow(cop).to receive(:in_migration?).and_return(true)

    expect_no_offenses(<<~RUBY)
      Worker.bulk_perform_in(args)
    RUBY
  end

  it "does not add an offence for specs" do
    allow(cop).to receive(:in_spec?).and_return(true)

    expect_no_offenses(<<~RUBY)
      Worker.bulk_perform_in(args)
    RUBY
  end

  it "does not add an offense for scheduling on the BackgroundMigrationWorker" do
    expect_no_offenses(<<~RUBY)
      BackgroundMigrationWorker.bulk_perform_in(args)
    RUBY
  end

  it "does not add an offense for scheduling on the CiDatabaseWorker" do
    expect_no_offenses(<<~RUBY)
      BackgroundMigration::CiDatabaseWorker.bulk_perform_in(args)
    RUBY
  end
end
