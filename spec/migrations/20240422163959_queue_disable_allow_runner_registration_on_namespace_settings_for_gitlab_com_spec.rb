# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueDisableAllowRunnerRegistrationOnNamespaceSettingsForGitlabCom, feature_category: :runner do
  let!(:batched_migration) { described_class::MIGRATION }

  context 'when on self managed' do
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

  context 'when on SaaS', :saas do
    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
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

  context 'when instance is dedicated' do
    before do
      Gitlab::CurrentSettings.update!(gitlab_dedicated_instance: true)
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
