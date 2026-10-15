# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddMcpServerEnabledIndexToRecentGroupAuditEventsPartitions, feature_category: :mcp_server do
  let(:migration) { described_class.new }
  let(:recent_partition) do
    Gitlab::Database::PostgresPartition.for_parent_table(:group_audit_events).order(:name).last.identifier
  end

  let(:old_partition) { 'gitlab_partitions_dynamic.group_audit_events_000000' }

  before do
    # The harness migrates down before this stub applies, so the gated `down` can leave a
    # previous example's index behind. Drop it here.
    allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    migration.down

    allow(Gitlab).to receive(:com_except_jh?).and_return(gitlab_com)
  end

  def index_name(partition)
    migration.send(:generated_index_name, partition, described_class::INDEX_NAME)
  end

  def index_on?(partition)
    migration.index_exists_by_name?(partition, index_name(partition))
  end

  context 'on GitLab.com' do
    let(:gitlab_com) { true }

    it 'creates the index only on partitions the background migration reads' do
      reversible_migration do |m|
        m.before -> {
          expect(index_on?(recent_partition)).to be(false)
          expect(index_on?(old_partition)).to be(false)
        }

        m.after -> {
          expect(index_on?(recent_partition)).to be(true)
          expect(index_on?(old_partition)).to be(false)
        }
      end
    end

    it 'removes the queued async index for the partitions it builds' do
      Gitlab::Database::AsyncIndexes::PostgresAsyncIndex.create!(
        name: index_name(recent_partition),
        table_name: recent_partition,
        definition: 'CREATE INDEX ...'
      )

      expect { migrate! }.to change {
        Gitlab::Database::AsyncIndexes::PostgresAsyncIndex.where(table_name: recent_partition).count
      }.from(1).to(0)
    end
  end

  context 'on other installations' do
    let(:gitlab_com) { false }

    it 'does not create the index' do
      reversible_migration do |m|
        m.before -> { expect(index_on?(recent_partition)).to be(false) }
        m.after -> { expect(index_on?(recent_partition)).to be(false) }
      end
    end
  end
end
