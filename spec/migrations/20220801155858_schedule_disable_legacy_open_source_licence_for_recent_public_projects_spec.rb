# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleDisableLegacyOpenSourceLicenceForRecentPublicProjects,
  schema: 20220801155858, feature_category: :projects do
  context 'when on gitlab.com' do
    let(:background_migration) { described_class::MIGRATION }
    let(:migration) { described_class.new }

    before do
      allow(Gitlab).to receive(:com?).and_return(true)
      migration.up
    end

    describe '#up' do
      it 'schedules background jobs for each batch of projects' do
        expect(background_migration).to(
          have_scheduled_batched_migration(
            table_name: :projects,
            column_name: :id,
            interval: described_class::INTERVAL,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        )
      end
    end

    describe '#down' do
      it 'deletes all batched migration records' do
        migration.down

        expect(described_class::MIGRATION).not_to have_scheduled_batched_migration
      end
    end
  end

  context 'when on self-managed instances' do
    let(:migration) { described_class.new }

    before do
      allow(Gitlab).to receive(:com?).and_return(false)
    end

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
