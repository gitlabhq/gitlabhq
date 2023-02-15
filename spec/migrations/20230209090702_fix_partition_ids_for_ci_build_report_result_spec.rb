# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixPartitionIdsForCiBuildReportResult,
  migration: :gitlab_ci,
  feature_category: :continuous_integration do
  let(:migration) { described_class::MIGRATION }

  context 'when on saas' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    describe '#up' do
      it 'schedules background jobs for each batch of ci_build_report_results' do
        migrate!

        expect(migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_ci,
          table_name: :ci_build_report_results,
          column_name: :build_id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      end
    end

    describe '#down' do
      it 'deletes all batched migration records' do
        migrate!
        schema_migrate_down!

        expect(migration).not_to have_scheduled_batched_migration
      end
    end
  end

  context 'when on self-managed instance' do
    let(:migration) { described_class.new }

    describe '#up' do
      it 'does not schedule background job' do
        expect(migration).not_to receive(:queue_batched_background_migration)

        migration.up
      end
    end

    describe '#down' do
      it 'does not delete background job' do
        expect(migration).not_to receive(:delete_batched_background_migration)

        migration.down
      end
    end
  end
end
