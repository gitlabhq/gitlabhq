# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueLimitNamespaceVisibilityByOrganizationVisibility, migration: :gitlab_main_org, feature_category: :groups_and_projects do
  let!(:batched_migration) { described_class::MIGRATION }

  context 'when on gitlab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            gitlab_schema: :gitlab_main_org,
            table_name: :namespaces,
            column_name: :id,
            interval: described_class::DELAY_INTERVAL,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        }
      end
    end
  end

  context 'when not on gitlab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    it 'does not schedule a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }
      end
    end
  end
end
