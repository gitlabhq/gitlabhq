# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleDisableLegacyOpenSourceLicenseForProjectsLessThanFiveMb, feature_category: :projects do
  let!(:migration) { described_class.new }
  let!(:post_migration) { described_class::MIGRATION }

  context 'when on gitlab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    describe '#up' do
      it 'schedules background jobs for each batch of project_settings' do
        migration.up

        expect(post_migration).to(
          have_scheduled_batched_migration(
            table_name: :project_settings,
            column_name: :project_id,
            interval: described_class::INTERVAL,
            batch_size: described_class::BATCH_SIZE,
            max_batch_size: described_class::MAX_BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        )
      end
    end

    describe '#down' do
      it 'deletes all batched migration records' do
        migration.down

        expect(post_migration).not_to have_scheduled_batched_migration
      end
    end
  end

  context 'when on self-managed instance' do
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
