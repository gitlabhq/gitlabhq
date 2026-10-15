# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueMcpServerDefaultTrueForGroups, migration: :gitlab_main_org, feature_category: :mcp_server do
  let!(:batched_migration) { described_class::MIGRATION }

  before do
    allow(Gitlab).to receive(:com_except_jh?).and_return(gitlab_com)
  end

  context 'on GitLab.com' do
    let(:gitlab_com) { true }

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            table_name: :namespaces,
            column_name: :id,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE,
            gitlab_schema: :gitlab_main_org,
            job_arguments: []
          )
        }
      end
    end
  end

  context 'on other installations' do
    let(:gitlab_com) { false }

    it 'does not schedule the batched migration' do
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
