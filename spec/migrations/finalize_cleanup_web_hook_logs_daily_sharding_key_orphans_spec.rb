# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeCleanupWebHookLogsDailyShardingKeyOrphans, migration: :gitlab_main_org, feature_category: :webhooks do
  let(:migration_arguments) do
    {
      job_class_name: 'CleanupWebHookLogsDailyShardingKeyOrphans',
      table_name: :web_hook_logs_daily,
      column_name: :id,
      job_arguments: [],
      finalize: true
    }
  end

  context 'when not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    it 'finalizes the batched background migration' do
      expect(described_class).to ensure_batched_background_migration_is_finished_for(migration_arguments)

      migrate!
    end
  end

  context 'when on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'does not finalize the batched background migration' do
      expect(described_class).not_to ensure_batched_background_migration_is_finished_for(migration_arguments)

      migrate!
    end
  end
end
