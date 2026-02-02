# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueCleanupSecurityPolicyBotUsers, feature_category: :security_policy_management do
  let!(:batched_migration) { described_class::MIGRATION }

  before do
    allow(Gitlab).to receive(:com_except_jh?).and_return(gitlab_com)
  end

  describe '#up' do
    context 'on GitLab.com' do
      let(:gitlab_com) { true }

      it 'schedules the batched background migration' do
        reversible_migration do |migration|
          migration.before -> {
            expect(batched_migration).not_to have_scheduled_batched_migration
          }

          migration.after -> {
            expect(batched_migration).to have_scheduled_batched_migration(
              gitlab_schema: :gitlab_main,
              table_name: :users,
              column_name: :id,
              interval: described_class::DELAY_INTERVAL,
              batch_size: described_class::BATCH_SIZE,
              sub_batch_size: described_class::SUB_BATCH_SIZE
            )
          }
        end
      end
    end

    context 'on self-managed' do
      let(:gitlab_com) { false }

      it 'does not schedule the batched background migration' do
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
end
