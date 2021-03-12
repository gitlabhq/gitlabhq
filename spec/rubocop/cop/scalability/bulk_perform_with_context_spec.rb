# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/scalability/bulk_perform_with_context'

RSpec.describe RuboCop::Cop::Scalability::BulkPerformWithContext do
  subject(:cop) { described_class.new }

  it "adds an offense when calling bulk_perform_async" do
    expect_offense(<<~CODE)
      Worker.bulk_perform_async(args)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer using `Worker.bulk_perform_async_with_contexts` [...]
    CODE
  end

  it "adds an offense when calling bulk_perform_in" do
    expect_offense(<<~CODE)
      diffs.each_batch(of: BATCH_SIZE) do |relation, index|
        ids = relation.pluck_primary_key.map { |id| [id] }
        DeleteDiffFilesWorker.bulk_perform_in(index * 5.minutes, ids)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer using `Worker.bulk_perform_async_with_contexts` [...]
      end
    CODE
  end

  it "does not add an offense for migrations" do
    allow(cop).to receive(:in_migration?).and_return(true)

    expect_no_offenses(<<~CODE)
      Worker.bulk_perform_in(args)
    CODE
  end

  it "does not add an offence for specs" do
    allow(cop).to receive(:in_spec?).and_return(true)

    expect_no_offenses(<<~CODE)
      Worker.bulk_perform_in(args)
    CODE
  end

  it "does not add an offense for scheduling BackgroundMigrations" do
    expect_no_offenses(<<~CODE)
      BackgroundMigrationWorker.bulk_perform_in(args)
    CODE
  end
end
