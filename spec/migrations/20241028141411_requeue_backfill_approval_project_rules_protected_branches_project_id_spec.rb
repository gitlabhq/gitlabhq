# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueBackfillApprovalProjectRulesProtectedBranchesProjectId, feature_category: :source_code_management do
  let!(:batched_migration) { described_class::MIGRATION }
  let(:expected_job_args) { %i[project_id approval_project_rules project_id approval_project_rule_id] }

  it 'does not schedule a new batched migratio' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }
    end
  end

  context 'when executed on .com' do
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
            table_name: described_class::TABLE_NAME,
            column_name: described_class::BATCH_COLUMN,
            interval: described_class::DELAY_INTERVAL,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE,
            gitlab_schema: :gitlab_main_org,
            job_arguments: expected_job_args
          )
        }
      end
    end
  end
end
