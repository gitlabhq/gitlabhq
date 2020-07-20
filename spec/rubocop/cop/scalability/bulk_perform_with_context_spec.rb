# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../../rubocop/cop/scalability/bulk_perform_with_context'

RSpec.describe RuboCop::Cop::Scalability::BulkPerformWithContext, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  it "adds an offense when calling bulk_perform_async" do
    inspect_source(<<~CODE)
      Worker.bulk_perform_async(args)
    CODE

    expect(cop.offenses.size).to eq(1)
  end

  it "adds an offense when calling bulk_perform_in" do
    inspect_source(<<~CODE)
      diffs.each_batch(of: BATCH_SIZE) do |relation, index|
        ids = relation.pluck_primary_key.map { |id| [id] }
        DeleteDiffFilesWorker.bulk_perform_in(index * 5.minutes, ids)
      end
    CODE

    expect(cop.offenses.size).to eq(1)
  end

  it "does not add an offense for migrations" do
    allow(cop).to receive(:in_migration?).and_return(true)

    inspect_source(<<~CODE)
      Worker.bulk_perform_in(args)
    CODE

    expect(cop.offenses.size).to eq(0)
  end

  it "does not add an offence for specs" do
    allow(cop).to receive(:in_spec?).and_return(true)

    inspect_source(<<~CODE)
      Worker.bulk_perform_in(args)
    CODE

    expect(cop.offenses.size).to eq(0)
  end

  it "does not add an offense for scheduling BackgroundMigrations" do
    inspect_source(<<~CODE)
      BackgroundMigrationWorker.bulk_perform_in(args)
    CODE

    expect(cop.offenses.size).to eq(0)
  end
end
