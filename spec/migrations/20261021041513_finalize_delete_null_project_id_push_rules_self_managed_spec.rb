# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeDeleteNullProjectIdPushRulesSelfManaged, feature_category: :source_code_management do
  let!(:background_migration) do
    table(:batched_background_migrations).create!(
      job_class_name: 'DeleteNullProjectIdPushRules',
      table_name: 'push_rules',
      column_name: 'id',
      job_arguments: [],
      batch_size: 1_000,
      sub_batch_size: 100,
      interval: 120,
      gitlab_schema: 'gitlab_main',
      queued_migration_version: 20260805094315,
      min_value: 1,
      max_value: 2,
      status: 3 # Finished
    )
  end

  context 'on self-managed' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    it 'finalizes the requeued background migration' do
      migrate!

      expect(background_migration.reload.status).to eq(6) # Finalized
    end
  end

  context 'on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'does not finalize the background migration' do
      expect { migrate! }.not_to change { background_migration.reload.status }
    end
  end
end
