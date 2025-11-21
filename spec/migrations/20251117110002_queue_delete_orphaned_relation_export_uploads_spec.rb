# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueDeleteOrphanedRelationExportUploads, migration: :gitlab_main, feature_category: :importers do
  let(:migration) { described_class.new }
  let(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_main,
          table_name: :uploads,
          column_name: :id,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          max_batch_size: described_class::MAX_BATCH_SIZE
        )
      }
    end
  end

  it 'uses the correct migration class' do
    expect(described_class::MIGRATION).to eq('DeleteOrphanedRelationExportUploads')
  end

  it 'sets the correct batch size' do
    expect(described_class::BATCH_SIZE).to eq(3_000)
  end

  it 'sets the correct sub-batch size' do
    expect(described_class::SUB_BATCH_SIZE).to eq(250)
  end

  it 'sets the correct max batch size' do
    expect(described_class::MAX_BATCH_SIZE).to eq(10_000)
  end
end
